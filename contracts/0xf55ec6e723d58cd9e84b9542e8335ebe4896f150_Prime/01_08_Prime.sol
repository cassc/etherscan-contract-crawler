// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

import {Initializable} from '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

import {IPrime} from './IPrime.sol';
import {Asset} from './Asset.sol';

import {NZAGuard} from '../utils/NZAGuard.sol';

/// @title A contract for control Clearpool Prime membership database
contract Prime is Initializable, OwnableUpgradeable, IPrime, NZAGuard {
  using Asset for Asset.Data;

  /// @notice Standart year in seconds
  uint256 public constant YEAR = 360 days;

  /// @notice Setted penalty rate per year value
  uint256 public penaltyRatePerYear;

  /// @dev Protocol spread rate
  uint256 public spreadRate; // from 0 (0%) to 1e18 (100%)

  /// @notice Origination fee rate
  uint256 public originationRate;

  /// @notice Rolling increment rate for the origination fee
  uint256 public incrementPerRoll;

  /// @dev The address that will receive the fees
  address public treasury;

  /// @dev Data struct to simplify the operations with stablecoins addresses
  Asset.Data private _stablecoins;

  /// @dev A record of each member's info, by address
  mapping(address => Member) private _members;

  /// @notice An event that's emitted when a member is created
  event MemberCreated(address indexed member);
  /// @notice An event that's emitted when a member is whitelisted
  event MemberWhitelisted(address indexed member);
  /// @notice An event that's emitted when a member is blacklisted
  event MemberBlacklisted(address indexed member);

  /// @notice An event that's emitted when a member's riskScore is changed
  event RiskScoreChanged(address indexed member, uint256 score);

  /// @notice An event that's emitted when the value of the penaltyRatePerYear is changed
  event PenaltyRatePerYearUpdated(uint256 oldValue, uint256 newValue);

  /// @notice An event that's emitted when the value of the spreadRate is changed
  event SpreadRateChanged(uint256 oldValue, uint256 newValue);

  /// @notice An event that's emitted when the value of the treasury is changed
  event TreasuryChanged(address oldValue, address newValue);

  /// @notice Emitted when origination fee rate is changed
  event OriginationRateChanged(uint256 oldFee, uint256 newFee);

  /// @notice Emitted when rolling increment rate is changed
  event RollingIncrementChanged(uint256 oldIncrement, uint256 newIncrement);

  /// @dev Modifier for checking membership record availability
  modifier onlyMember(address _member) {
    require(_members[_member].created, 'NPM');
    _;
  }

  /// @dev Modifier for checking that risk score is in range of [1, 100]
  modifier riskScoreInRange(uint256 _riskScore) {
    require(_riskScore <= 100 && _riskScore > 0, 'RSI');
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {
    _disableInitializers();
  }

  /// @dev External function to initialize the contract after it's been added to the proxy.
  /// @dev It initializes the inherited contracts.
  /// @param stablecoins An array of stablecoins addresses
  /// @param treasury_ The address that will receive the fees
  /// @param penaltyRatePerYear_ The penalty rate per year
  function __Prime_init(
    address[] memory stablecoins,
    address treasury_,
    uint256 penaltyRatePerYear_
  ) external virtual initializer {
    __Ownable_init();
    __Prime_init_unchained(stablecoins, treasury_, penaltyRatePerYear_);
  }

  /// @dev Internal function to initialize the contract after it's been added to the proxy
  /// @dev It initializes current contract with the given parameters.
  /// @param stablecoins An array of stablecoins addresses
  /// @param treasury_ The address that will receive the fees
  /// @param penaltyRatePerYear_ The penalty rate per year
  function __Prime_init_unchained(
    address[] memory stablecoins,
    address treasury_,
    uint256 penaltyRatePerYear_
  ) internal nonZeroAddress(treasury_) nonZeroValue(penaltyRatePerYear_) onlyInitializing {
    require(penaltyRatePerYear_ <= 1e19, 'PRI'); // 1000%;
    treasury = treasury_;
    penaltyRatePerYear = penaltyRatePerYear_;

    for (uint256 i = 0; i < stablecoins.length; i++) {
      require(_stablecoins.insert(stablecoins[i]), 'TIF');
    }
  }

  /**
   * @inheritdoc IPrime
   */
  function isMember(address _member) external view override returns (bool) {
    Member storage member = _members[_member];
    return member.created && member.status == MemberStatus.WHITELISTED;
  }

  /**
   * @inheritdoc IPrime
   */
  function isAssetAvailable(
    address asset
  ) external view override nonZeroAddress(asset) returns (bool isAvailable) {
    return _stablecoins.contains(asset);
  }

  /// @notice Returns an array of assets available for borrowing
  /// @return An array of available assets
  function availableAssets() external view returns (address[] memory) {
    return _stablecoins.getList();
  }

  /**
   * @inheritdoc IPrime
   */
  function membershipOf(address _member) external view override returns (Member memory member) {
    return _members[_member];
  }

  /**
   * @notice Request a membership record
   *
   *
   * @dev Emits a {MemberCreated} event.
   */
  function requestMembership(address _requester) public nonZeroAddress(_requester) {
    require(!_members[_requester].created, 'MAC');

    _members[_requester] = Member(0, MemberStatus.PENDING, true);
    emit MemberCreated(_requester);
  }

  /**
   * @notice Alter or creates membership record by setting `_member` status and `_riskScore`
   * @param _member The member address
   * @param _riskScore The number up to 100 representing member's score
   *
   * @dev Emits a {MemberCreated} event.
   * @dev Emits a {MemberWhitelisted} event.
   * @dev Emits a {RiskScoreChanged} event.
   */
  function whitelistMember(
    address _member,
    uint256 _riskScore
  ) external nonZeroAddress(_member) riskScoreInRange(_riskScore) onlyOwner {
    _whitelistMember(_member, _riskScore);
  }

  /// @dev Internal function that whitelists member
  /// @param _member The member address
  /// @param _riskScore The number up to 100 representing member's score
  function _whitelistMember(address _member, uint256 _riskScore) internal {
    Member storage member = _members[_member];

    if (!member.created) {
      requestMembership(_member);
    }

    require(member.status != MemberStatus.WHITELISTED, 'AAD');

    member.status = MemberStatus.WHITELISTED;
    emit MemberWhitelisted(_member);

    if (member.riskScore != _riskScore) {
      member.riskScore = _riskScore;
      emit RiskScoreChanged(_member, _riskScore);
    }
  }

  /**
   * @notice Alter membership record by setting `_member` status
   * @param _member The member address
   *
   * @dev Emits a {MemberBlacklisted} event.
   */
  function blacklistMember(
    address _member
  ) external nonZeroAddress(_member) onlyMember(_member) onlyOwner {
    Member storage member = _members[_member];

    require(member.status != MemberStatus.BLACKLISTED, 'AAD');

    member.status = MemberStatus.BLACKLISTED;
    emit MemberBlacklisted(_member);
  }

  /**
   * @notice Alter membership record by setting member `_riskScore`
   * @param _member The member address
   * @param _riskScore The number up to 100 representing member's score
   *
   * @dev Emits a {RiskScoreChanged} event.
   */
  function changeMemberRiskScore(
    address _member,
    uint256 _riskScore
  ) external nonZeroAddress(_member) onlyMember(_member) riskScoreInRange(_riskScore) onlyOwner {
    Member storage member = _members[_member];
    if (member.riskScore != _riskScore) {
      member.riskScore = _riskScore;
      emit RiskScoreChanged(_member, _riskScore);
    }
  }

  /**
   * @notice Changes the spread rate
   * @dev Callable only by owner. It is a mantissa value, so 1e18 is 100%
   * @param spreadRate_ New spread fee rate
   */
  function changeSpreadRate(
    uint256 spreadRate_
  ) external onlyOwner nonMoreThenOne(spreadRate_) nonSameValue(spreadRate_, spreadRate) {
    uint256 currentValue = spreadRate;
    spreadRate = spreadRate_;
    emit SpreadRateChanged(currentValue, spreadRate_);
  }

  /// @notice Changes the origination fee rate
  /// @dev Callable only by owner
  /// @param _originationRate New origination fee rate
  function setOriginationRate(
    uint256 _originationRate
  )
    external
    onlyOwner
    nonMoreThenOne(_originationRate)
    nonSameValue(_originationRate, originationRate)
  {
    uint256 currentFee = originationRate;

    originationRate = _originationRate;
    emit OriginationRateChanged(currentFee, _originationRate);
  }

  /// @notice Changes the rolling increment fee rate
  /// @dev Callable only by owner
  /// @param _incrementPerRoll New origination fee rate
  function setRollingIncrement(
    uint256 _incrementPerRoll
  )
    external
    onlyOwner
    nonMoreThenOne(_incrementPerRoll)
    nonSameValue(_incrementPerRoll, incrementPerRoll)
  {
    uint256 currentIncrement = incrementPerRoll;

    incrementPerRoll = _incrementPerRoll;
    emit RollingIncrementChanged(currentIncrement, _incrementPerRoll);
  }

  /// @notice Sets a new treasury address for the contract
  /// @dev Callable only by owner
  /// @param treasury_ The address of the new treasury
  function setTreasury(
    address treasury_
  ) external nonZeroAddress(treasury_) nonSameAddress(treasury_, treasury) onlyOwner {
    address currentValue = treasury;

    treasury = treasury_;
    emit TreasuryChanged(currentValue, treasury_);
  }

  /// @notice Updates penalty rate per year value
  /// @dev Callable only by owner
  /// @param penaltyRatePerYear_ New penalty rate per year value
  function updatePenaltyRatePerYear(
    uint256 penaltyRatePerYear_
  ) external onlyOwner nonSameValue(penaltyRatePerYear_, penaltyRatePerYear) {
    require(penaltyRatePerYear_ <= 1e19, 'PRI'); // 1000%;
    uint256 currentValue = penaltyRatePerYear;

    penaltyRatePerYear = penaltyRatePerYear_;
    emit PenaltyRatePerYearUpdated(currentValue, penaltyRatePerYear_);
  }
}