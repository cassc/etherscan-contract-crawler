// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import {IBackstop, Terms, TermsProposal} from "crate/interfaces/IBackstop.sol";
import {IERC20} from "openzeppelin-contracts/contracts/interfaces/IERC20.sol";
import {ISeniorPool} from "crate/interfaces/ISeniorPool.sol";
import {Math} from "openzeppelin-contracts/contracts/utils/math/Math.sol";
import {Ownable} from "crate/Ownable.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMathExt} from "crate/library/SafeMathExt.sol";
import {IFiduLense} from "crate/interfaces/IFiduLense.sol";
import {Address} from "openzeppelin-contracts/contracts/utils/Address.sol";

using SafeERC20 for IERC20;
using SafeMathExt for uint256;
using Math for uint256;
using TermsLib for Terms;
using TermsProposalLib for TermsProposal;

/**
 * @title Backstop
 * @author Warbler Labs Engineering
 * @notice This contract provides a "liquidity buffer" to the senior pool that allows an address
 *         agreed on by the "owner" and the governor to swap their FIDU to USDC using the buffer,
 *         provided they have enough FIDU.
 */
contract Backstop is Ownable, IBackstop {
  /// @inheritdoc IBackstop
  IERC20 public immutable fidu;

  /// @inheritdoc IBackstop
  IERC20 public immutable usdc;

  /// @inheritdoc IBackstop
  address public governor;

  /// @notice Currently active backstop terms
  Terms internal _activeTerms;

  /// @notice Proposed terms
  TermsProposal internal _proposedTerms;

  /**
   * @notice Constructor
   * @param _owner owner of contract
   * @param _governor owner of governor role
   * @param _usdc USDC contract
   * @param _fidu FIDU contract
   */
  constructor(address _owner, address _governor, IERC20 _usdc, IERC20 _fidu) Ownable(_owner) {
    governor = _governor;
    usdc = _usdc;
    fidu = _fidu;
  }

  /* ================================================================================
                                View Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function isActive() public view returns (bool) {
    return block.timestamp < _activeTerms.endTime;
  }

  /// @inheritdoc IBackstop
  function activeTerms() external view returns (Terms memory) {
    return _activeTerms;
  }

  /// @inheritdoc IBackstop
  function proposedTerms() external view returns (TermsProposal memory) {
    return _proposedTerms;
  }

  /// @inheritdoc IBackstop
  function swapper() public view returns (address) {
    return _activeTerms.swapper;
  }

  /// @inheritdoc IBackstop
  function backstopUsed() public view returns (uint256) {
    return _activeTerms.backstopUsed;
  }

  /// @inheritdoc IBackstop
  function backstopAvailable() public view returns (uint256) {
    if (!isActive()) {
      return 0;
    }

    uint256 swapperPositionValue = _activeTerms.lense.fiduPositionValue(_activeTerms.swapper);
    uint256 percentOfPosition = swapperPositionValue.decMul(_activeTerms.backstopPercentage);

    uint256 upperBound = percentOfPosition.min(_activeTerms.maxBackstopAmount);

    return upperBound.saturatingSub(_activeTerms.backstopUsed);
  }

  /* ================================================================================
                                Owner Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function proposeTerms(TermsProposal calldata terms) external onlyOwner {
    terms.validate();

    _proposedTerms = terms;
    emit TermsProposed({
      from: msg.sender,
      swapper: _proposedTerms.swapper,
      endTime: _proposedTerms.endTime,
      lense: _proposedTerms.lense,
      backstopPercentage: _proposedTerms.backstopPercentage,
      maxBackstopAmount: _proposedTerms.maxBackstopAmount
    });
  }

  // @inheritdoc IBackstop
  function previewSweep() public view returns (uint256, uint256) {
    uint256 usdcAvailable = isActive()
      ? usdc.balanceOf(address(this)).saturatingSub(_activeTerms.maxBackstopAmount)
      : usdc.balanceOf(address(this));
    uint256 fiduAvailable = isActive() ? 0 : fidu.balanceOf(address(this));
    return (usdcAvailable, fiduAvailable);
  }

  /// @inheritdoc IBackstop
  function sweep() external onlyOwner returns (uint256, uint256) {
    (uint256 usdcAmount, uint256 fiduAmount) = previewSweep();

    // early return to avoid gas
    if (usdcAmount == 0 && fiduAmount == 0) {
      return (0, 0);
    }

    usdc.safeTransfer(msg.sender, usdcAmount);
    fidu.safeTransfer(msg.sender, fiduAmount);

    emit FundsSwept({from: msg.sender, usdcAmount: usdcAmount, fiduAmount: fiduAmount});

    return (usdcAmount, fiduAmount);
  }

  /* ================================================================================
                                Governor Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function transferGovernor(address newGovernor) external onlyGovernor {
    address oldGovernor = governor;
    governor = newGovernor;
    emit GovernorTransferred(oldGovernor, governor);
  }

  function acceptTerms(
    uint64 _endTime,
    IFiduLense _lense,
    address _swapper,
    uint256 _maxBackstopAmount,
    uint64 _backstopPercentage
  ) external {
    TermsProposal memory t = TermsProposal({
      endTime: _endTime,
      lense: _lense,
      swapper: _swapper,
      maxBackstopAmount: _maxBackstopAmount,
      backstopPercentage: _backstopPercentage
    });

    if (!_proposedTerms.eq(t)) {
      revert ProposedTermsDontMatch();
    }

    return _acceptTerms();
  }

  /// @inheritdoc IBackstop
  function acceptTerms() external {
    return _acceptTerms();
  }

  function _acceptTerms() internal onlyGovernor {
    if (_proposedTerms.isEmpty()) {
      revert NoProposedTerms();
    }

    _proposedTerms.validate();

    _activeTerms.initFromTermsProposal(_proposedTerms);
    // clear it so that you can't re-accept the same terms
    // without the owner proposing them
    _proposedTerms.clear();

    emit TermsAccepted({
      from: msg.sender,
      swapper: _activeTerms.swapper,
      endTime: _activeTerms.endTime,
      lense: _activeTerms.lense,
      backstopPercentage: _activeTerms.backstopPercentage,
      maxBackstopAmount: _activeTerms.maxBackstopAmount
    });
  }

  /* ================================================================================
                                Swapper Functions
  ================================================================================ */

  /// @inheritdoc IBackstop
  function previewSwapUsdcForFidu(uint256 usdcAmount)
    external
    view
    whileActive
    onlySwapper
    returns (uint256)
  {
    uint256 asFidu = _usdcToFidu(usdcAmount);
    if (usdcAmount > _activeTerms.backstopUsed || asFidu > fidu.balanceOf(address(this))) {
      revert InsufficientBalanceToSwap();
    }

    return asFidu;
  }

  /// @inheritdoc IBackstop
  function swapUsdcForFidu(uint256 usdcAmount) external onlySwapper whileActive returns (uint256) {
    if (usdcAmount == 0) {
      revert ZeroValueSwap();
    }

    uint256 fiduAmount = _usdcToFidu(usdcAmount);

    _activeTerms.backstopUsed -= usdcAmount;

    usdc.safeTransferFrom(msg.sender, address(this), usdcAmount);
    fidu.safeTransfer(msg.sender, fiduAmount);

    emit SwapUsdcForFidu({from: msg.sender, usdcAmount: usdcAmount, fiduReceived: fiduAmount});

    return fiduAmount;
  }

  /// @inheritdoc IBackstop
  function previewSwapFiduForUsdc(uint256 fiduAmount)
    external
    view
    onlySwapper
    whileActive
    returns (uint256)
  {
    uint256 asUsdc = _fiduToUsdc(fiduAmount);
    if (asUsdc > backstopAvailable()) {
      revert InsufficientBalanceToSwap();
    }

    return asUsdc;
  }

  /// @inheritdoc IBackstop
  function swapFiduForUsdc(uint256 fiduAmount) external onlySwapper whileActive returns (uint256) {
    if (fiduAmount == 0) {
      revert ZeroValueSwap();
    }

    uint256 usdcAmount = _fiduToUsdc(fiduAmount);
    uint256 available = backstopAvailable();

    // If the amount received is 0 there's no point in doing the swap
    if (usdcAmount == 0) {
      revert ZeroValueSwap();
    }

    if (usdcAmount > available || available == 0) {
      revert InsufficientBalanceToSwap();
    }

    _activeTerms.backstopUsed += usdcAmount;

    fidu.safeTransferFrom(msg.sender, address(this), fiduAmount);
    usdc.safeTransfer(msg.sender, usdcAmount);

    emit SwapFiduForUsdc({from: msg.sender, fiduAmount: fiduAmount, usdcReceived: usdcAmount});
    return usdcAmount;
  }

  /* ================================================================================
                            Internal Functions
  ================================================================================ */

  function _usdcToFidu(uint256 fiduAmount) internal view returns (uint256) {
    return _activeTerms.lense.usdcToFidu(fiduAmount);
  }

  function _fiduToUsdc(uint256 usdcAmount) internal view returns (uint256) {
    return _activeTerms.lense.fiduToUsdc(usdcAmount);
  }

  /* ================================================================================
                                   Modifiers
  ================================================================================ */

  modifier onlyGovernor() {
    if (msg.sender != governor) {
      revert NotGovernor();
    }
    _;
  }

  modifier onlySwapper() {
    if (msg.sender != _activeTerms.swapper) {
      revert NotSwapper();
    }
    _;
  }

  modifier whileActive() {
    if (block.timestamp >= _activeTerms.endTime) {
      revert TermOver();
    }
    _;
  }

  /* ================================================================================
                                     Errors
  ================================================================================ */
  /// @notice Thrown when the governor is trying to accept a set of proposed terms that does not match what they expect
  error ProposedTermsDontMatch();
  /// @notice Thrown when the governor is trying to accept terms where none exist
  error NoProposedTerms();
  /// @notice Thrown when a function only callable by the governor is called by somebody else
  error NotGovernor();
  /// @notice Thrown when a function only callable by the swapper is called by somebody else
  error NotSwapper();
  /// @notice Thrown when a function is called that only applies during the term
  error TermOver();
  /// @notice Thrown when the swapper is attempting to swap fidu for USDC but does not have fidu holdings
  error InsufficientBalanceToSwap();
  /// @notice Thrown when a swap would result in
  error ZeroValueSwap();
}

library TermsLib {
  /// @notice Initialize a Terms struct using a TermsProposal struct
  function initFromTermsProposal(Terms storage t, TermsProposal storage p) internal {
    t.endTime = p.endTime;
    t.backstopPercentage = p.backstopPercentage;
    t.lense = p.lense;
    t.swapper = p.swapper;
    t.maxBackstopAmount = p.maxBackstopAmount;
    t.backstopUsed = 0;
  }
}

library TermsProposalLib {
  /// @notice Validate that a given TermsProposal struct has legal values. Revert if not
  function validate(TermsProposal memory t) internal view {
    bool endTimeIsInPast = t.endTime < block.timestamp;
    if (endTimeIsInPast) {
      revert ProposedEndTimeIsInPast();
    }

    bool lensIsNotAContract = !Address.isContract(address(t.lense));
    if (lensIsNotAContract) {
      revert LenseIsNotAContract();
    }

    bool swapperIsNull = t.swapper == address(0);
    if (swapperIsNull) {
      revert SwapperIsNullAddress();
    }

    bool backstopPercentageIsInvalid = t.backstopPercentage > 1e18 || t.backstopPercentage == 0;
    if (backstopPercentageIsInvalid) {
      revert InvalidBackstopPercentage();
    }
  }

  /// @notice Returns true if all of the fields of a TermsProposal are zero
  function isEmpty(TermsProposal storage t) internal view returns (bool) {
    return t.endTime == 0 && t.lense == IFiduLense(address(0)) && t.swapper == address(0)
      && t.backstopPercentage == 0 && t.maxBackstopAmount == 0;
  }

  /// @notice Returns true if two terms proposals are equal
  function eq(TermsProposal memory a, TermsProposal memory b) internal pure returns (bool) {
    return a.endTime == b.endTime && a.lense == b.lense && a.swapper == b.swapper
      && a.maxBackstopAmount == b.maxBackstopAmount && a.backstopPercentage == b.backstopPercentage;
  }

  /// @notice Zero out the storage variables of a terms proposal
  function clear(TermsProposal storage t) internal {
    t.endTime = 0;
    t.backstopPercentage = 0;
    t.lense = IFiduLense(address(0));
    t.swapper = address(0);
    t.maxBackstopAmount = 0;
  }

  error ProposedEndTimeIsInPast();
  error LenseIsNotAContract();
  error SwapperIsNullAddress();
  error InvalidBackstopPercentage();
}