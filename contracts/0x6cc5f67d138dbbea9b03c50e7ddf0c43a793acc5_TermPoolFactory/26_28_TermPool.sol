// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IOwnable} from './interfaces/IOwnable.sol';
import {ITermPool} from './interfaces/ITermPool.sol';
import {ITermPoolFactory} from './interfaces/ITermPoolFactory.sol';
import {TpToken, ITpToken} from './TpToken.sol';
import {IPermissionlessPoolFactory} from './interfaces/IPermissionlessPoolFactory.sol';
import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {IERC20Upgradeable, IERC20MetadataUpgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import {SafeERC20Upgradeable} from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import {BeaconProxy} from '@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol';
import {EnumerableSet} from '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import {TermUtils} from './utils/TermUtils.sol';

/// @notice Contract for managing terms of the Term Protocol
contract TermPool is ITermPool, Initializable, TermUtils {
  using EnumerableSet for EnumerableSet.UintSet;
  using SafeERC20Upgradeable for IERC20Upgradeable;

  /// @notice TermPoolFactory address
  address public factory;

  /// @notice Base cpToken address
  address public cpToken;

  /// @notice Borrower address
  address public borrower;

  /// @notice Is pool listed in TermPoolFactory
  bool public isListed;

  /// @notice Internal value for calculating reward
  uint256 private constant MULTIPLIER = 1e18;

  /// @notice Internal constant value for YEAR representation
  uint256 public constant YEAR = 365 days;

  //TODO better to change it to mapping to improve performance or avoid out-of-gas error to fetch the list.
  /// @notice Array of all terms
  Term[] public terms;

  /// @notice the index value set for active term
  EnumerableSet.UintSet activeTermsIndex;

  mapping(uint256 => bool) internal partialRepaymentAllowance;

  /// @notice Modifier to check if the caller is the borrower
  modifier onlyBorrower() {
    if (msg.sender != borrower) revert NotBorrower(msg.sender);
    _;
  }

  /// @notice Modifier to check if the pool is listed
  modifier onlyListed() {
    if (!isListed) revert NotListed();
    _;
  }

  /// @notice Modifier to check if the term exists
  modifier existingTerm(uint256 _termId) {
    if (_termId >= terms.length) revert TermDoesntExist(_termId);
    _;
  }

  /// @notice Modifier to check if the caller is the owner of the TermPoolFactory
  modifier onlyFactoryOwner() {
    if (msg.sender != IOwnable(factory).owner()) revert NotOwner(msg.sender);
    _;
  }

  /// @notice Modifier to check if the caller is the TermPoolFactory
  modifier onlyFactory() {
    if (msg.sender != factory) revert NotFactory(msg.sender);
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @notice Initializes the upgradeable contract
  /// @param _cpToken Base cpToken address
  /// @param _borrower Borrower address
  /// @param _isListed Is pool listed in TermPoolFactory
  function __TermPool_init(
    address _cpToken,
    address _borrower,
    bool _isListed
  ) external initializer {
    cpToken = _cpToken;
    factory = msg.sender;
    borrower = _borrower;
    isListed = _isListed;
  }

  /// @notice List or delist pool in TermPoolFactory
  /// @dev Callable only by TermPoolFactory
  function setListed(bool _isListed) external onlyFactory {
    isListed = _isListed; // onlyFactoryOwner
    emit PoolListingChanged(isListed);
  }

  struct CreateTermLocalVars {
    uint8 decimals;
    string prefixSymbol;
    string currencySymbol;
    bytes prefix;
    bytes suffix;
    bytes tpSymbol;
    bytes encoded;
  }

  /// @notice Creates new term
  /// @dev Callable only by borrower
  /// @param _minSize Minimum term size
  /// @param _maxSize Maximum term size
  /// @param _startDate Deposit window start
  /// @param _depositWindow Deposit window duration
  /// @param _maturity Term duration
  /// @param _rewardRate Reward rate of the term
  function createTerm(
    uint256 _minSize,
    uint256 _maxSize,
    uint256 _startDate,
    uint256 _depositWindow,
    uint256 _maturity,
    uint256 _rewardRate
  ) external onlyBorrower {
    if (_minSize > _maxSize) revert WrongBoundaries(_minSize, _maxSize);

    if (_depositWindow == 0) revert ValueIsZero(_depositWindow);
    if (_startDate < block.timestamp || _depositWindow > _maturity)
      revert WrongBoundaries(_startDate, _depositWindow);

    if (_rewardRate == 0) revert ValueIsZero(_rewardRate);

    address tpTokenBeacon = ITermPoolFactory(factory).tpTokenBeacon();
    address tpTokenAddr = address(new BeaconProxy(tpTokenBeacon, ''));

    uint256 termId = terms.length;

    CreateTermLocalVars memory vars = CreateTermLocalVars(0, '', '', '', '', '', '');

    (vars.prefixSymbol, vars.currencySymbol) = sliceString(
      IERC20MetadataUpgradeable(cpToken).symbol()
    );

    vars.decimals = IERC20MetadataUpgradeable(cpToken).decimals();

    vars.prefix = bytes(vars.prefixSymbol);
    vars.suffix = bytes.concat(bytes(vars.currencySymbol), bytes('-'), uint2bytes(termId));
    vars.prefix[0] = 't';

    vars.encoded = abi.encodePacked(keccak256(vars.suffix));
    vars.tpSymbol = bytes.concat(vars.prefix, bytes('-'), store3Chars(vars.encoded));

    TpToken(tpTokenAddr).__TpToken_init(
      string(bytes.concat(bytes('Term Pool '), vars.prefix, bytes('-'), vars.suffix)),
      string(vars.tpSymbol),
      vars.decimals
    );

    terms.push(
      Term(
        _minSize,
        _maxSize,
        0,
        _startDate,
        _startDate + _depositWindow,
        _startDate + _maturity,
        _rewardRate,
        0,
        TermStatus.Created,
        tpTokenAddr
      )
    );

    activeTermsIndex.add(termId);

    emit TermCreated(
      termId,
      _minSize,
      _maxSize,
      _startDate,
      _depositWindow,
      _maturity,
      _rewardRate
    );
  }

  /// @notice Provides liquidity to the term
  /// @param _termId Id of the term
  /// @param _amount Amount of liquidity to lock
  function lock(
    uint256 _termId,
    uint256 _amount
  ) external override onlyListed existingTerm(_termId) {
    Term storage term = terms[_termId];

    if (block.timestamp > term.depositWindowMaturity || block.timestamp < term.startDate)
      revert NotInDepositWindow(term.startDate, term.depositWindowMaturity, block.timestamp);

    if (term.status == TermStatus.Cancelled) {
      revert TermCancelled(_termId);
    }
    if (term.maxSize < term.size + _amount) revert MaxPoolSizeOverflow(term.maxSize, term.size);

    term.size += _amount;
    ITpToken(term.tpToken).mint(msg.sender, _amount);
    emit LiquidityProvided(msg.sender, _termId, _amount);
    IERC20Upgradeable(cpToken).safeTransferFrom(msg.sender, address(this), _amount);
  }

  /// @notice Repays the term to the lender with reward
  /// @param _termId Id of the term
  function unlock(uint256 _termId) external override existingTerm(_termId) {
    Term storage term = terms[_termId];

    if (block.timestamp < term.maturityDate)
      revert NotEndedMaturity(term.maturityDate, block.timestamp);

    uint256 totalAmount = IERC20MetadataUpgradeable(term.tpToken).balanceOf(msg.sender);
    if (totalAmount == 0) revert ZeroAmount();

    uint256 reward = availableRewardOf(_termId, msg.sender);
    ITpToken(term.tpToken).burn(msg.sender, totalAmount);

    unchecked {
      term.availableReward -= reward;
      term.size -= totalAmount;
    }
    totalAmount += reward;

    if (term.size == 0) {
      _changeStatus(_termId, TermStatus.Repayed);
      activeTermsIndex.remove(_termId);
    }
    emit LiquidityRedeemed(msg.sender, _termId, totalAmount);
    IERC20Upgradeable(cpToken).safeTransfer(msg.sender, totalAmount);
  }

  /// @notice Topups the reward in the contract
  /// @dev Only borrower can call this function
  /// @param _amount Amount of tokens to repay
  function topupReward(
    uint256 _termId,
    uint256 _amount
  ) external override onlyBorrower existingTerm(_termId) {
    Term storage term = terms[_termId];

    if (block.timestamp < term.depositWindowMaturity) {
      revert NotInDepositWindow(term.startDate, term.depositWindowMaturity, block.timestamp);
    }

    uint256 termReward = (term.size *
      _annualRate(term.rewardRate, term.maturityDate - term.startDate)) / MULTIPLIER;

    if (!partialRepaymentAllowance[_termId] && termReward > _amount) {
      revert NotEnoughReward();
    }

    term.availableReward += _amount;
    if (termReward < term.availableReward) {
      revert MaxPoolSizeOverflow(termReward, term.availableReward);
    }

    emit RewardTopUp(_termId, _amount);
    IERC20Upgradeable(cpToken).safeTransferFrom(msg.sender, address(this), _amount);
  }

  function withdrawReward(
    uint256 _termId
  ) external override onlyFactoryOwner existingTerm(_termId) {
    Term storage term = terms[_termId];

    uint256 currentAvailableReward = term.availableReward;
    term.availableReward = 0;

    emit RewardDrop(_termId);
    IERC20Upgradeable(cpToken).safeTransfer(borrower, currentAvailableReward);
  }

  function allowPartialRepayment(
    uint256 _termId
  ) external override onlyFactoryOwner existingTerm(_termId) {
    partialRepaymentAllowance[_termId] = true;
    emit PartialRepaymentAllowed(_termId);
  }

  /// @notice Returns the amount of pending reward of the account
  /// @param _termId Id of the term
  /// @param _account Address of the account
  function rewardOf(
    uint256 _termId,
    address _account
  ) public view existingTerm(_termId) returns (uint256) {
    Term storage term = terms[_termId];
    uint256 balance = IERC20MetadataUpgradeable(term.tpToken).balanceOf(_account);
    if (balance > 0) {
      return
        (balance * _annualRate(term.rewardRate, term.maturityDate - term.startDate)) / MULTIPLIER;
    } else {
      return 0;
    }
  }

  /// @notice Returns the amount of available reward of the account to be unlocked at the moment
  /// @param _termId Id of the term
  /// @param _account Address of the account
  function availableRewardOf(
    uint256 _termId,
    address _account
  ) public view existingTerm(_termId) returns (uint256) {
    uint256 totalReward = rewardOf(_termId, _account);
    return (totalReward * _rewardAvailabilityRate(_termId)) / 1e18;
  }

  /// @notice Cancels the term if it's created with mistake
  /// @param _termId Address of the account
  function cancelTerm(uint256 _termId) external override existingTerm(_termId) onlyBorrower {
    Term storage term = terms[_termId];
    if (term.size > 0) {
      revert WrongTermState(TermStatus.Created, term.status);
    }

    if (term.status == TermStatus.Created) {
      _changeStatus(_termId, TermStatus.Cancelled);
      activeTermsIndex.remove(_termId);
    } else {
      revert WrongTermState(TermStatus.Created, term.status);
    }
  }

  /// @notice Returns all existing terms structs
  /// @return Array of terms
  function getAllTerms() external view returns (Term[] memory) {
    return terms;
  }

  function isActiveTerm(uint256 termId) external view returns (bool) {
    return activeTermsIndex.contains(termId);
  }

  function getActiveTermsIndex() public view returns (uint256[] memory) {
    return activeTermsIndex.values();
  }

  /// @notice Returns all active terms structs
  /// @return activeTerms array
  function getAllActiveTerms() external view returns (Term[] memory activeTerms) {
    activeTerms = new Term[](activeTermsIndex.length());
    for (uint256 i = 0; i < activeTermsIndex.length(); i++) {
      activeTerms[i] = terms[activeTermsIndex.at(i)];
    }
    return activeTerms;
  }

  /// @notice Internal function to change the term status and emit suitable event
  /// @param _termId Id of the term
  /// @param _status New status of the term
  function _changeStatus(uint256 _termId, TermStatus _status) internal {
    terms[_termId].status = _status;
    emit TermStatusChanged(_termId, _status);
  }

  /// @dev Calculates the annual rate for a given reward rate and specific interval
  /// @param _rateMantissa The reward rate as a mantissa between [0, 1e18]
  /// @param _timeDelta The interval in seconds
  /// @return rate as a mantissa between [0, 1e18]
  function _annualRate(uint256 _rateMantissa, uint256 _timeDelta) internal pure returns (uint256) {
    return (_rateMantissa * _timeDelta) / YEAR;
  }

  function _rewardAvailabilityRate(uint256 _termId) internal view returns (uint256) {
    Term storage term = terms[_termId];

    uint256 totalReward = (term.size *
      _annualRate(term.rewardRate, term.maturityDate - term.startDate)) / MULTIPLIER;

    if (totalReward == 0) return 0;
    return (term.availableReward * 1e18) / totalReward;
  }
}