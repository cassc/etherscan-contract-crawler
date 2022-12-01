// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {LinkTokenInterface} from '@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol';
import {TypeAndVersionInterface} from '@chainlink/contracts/src/v0.8/interfaces/TypeAndVersionInterface.sol';
import {AggregatorV3Interface} from '@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol';
import {ConfirmedOwner} from '@chainlink/contracts/src/v0.8/ConfirmedOwner.sol';
import {Pausable} from '@openzeppelin/contracts/security/Pausable.sol';
import {MerkleProof} from '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import {IERC165} from '@openzeppelin/contracts/interfaces/IERC165.sol';
import {Math} from '@openzeppelin/contracts/utils/math/Math.sol';
import {IStaking} from './interfaces/IStaking.sol';
import {IStakingOwner} from './interfaces/IStakingOwner.sol';
import {IMerkleAccessController} from './interfaces/IMerkleAccessController.sol';
import {IAlertsController} from './interfaces/IAlertsController.sol';
import {IMigratable} from './interfaces/IMigratable.sol';
import {StakingPoolLib} from './StakingPoolLib.sol';
import {RewardLib, SafeCast} from './RewardLib.sol';

contract Staking is
  IStaking,
  IStakingOwner,
  IMigratable,
  IMerkleAccessController,
  IAlertsController,
  ConfirmedOwner,
  TypeAndVersionInterface,
  Pausable
{
  using StakingPoolLib for StakingPoolLib.Pool;
  using RewardLib for RewardLib.Reward;
  using SafeCast for uint256;

  /// @notice This struct defines the params required by the Staking contract's
  /// constructor.
  struct PoolConstructorParams {
    /// @notice The LINK Token
    LinkTokenInterface LINKAddress;
    /// @notice The feed being monitored when raising alerts
    AggregatorV3Interface monitoredFeed;
    /// @notice The initial maximum total stake amount across all stakers
    uint256 initialMaxPoolSize;
    /// @notice The initial maximum stake amount for a single community staker
    uint256 initialMaxCommunityStakeAmount;
    /// @notice The initial maximum stake amount for a single node operator
    uint256 initialMaxOperatorStakeAmount;
    /// @notice The minimum stake amount that a community staker can stake
    uint256 minCommunityStakeAmount;
    /// @notice The minimum stake amount that an operator can stake
    uint256 minOperatorStakeAmount;
    /// @notice The number of seconds until the feed is considered stale
    /// and the priority period begins.
    uint256 priorityPeriodThreshold;
    /// @notice The number of seconds until the priority period ends
    /// and the regular period begins.
    uint256 regularPeriodThreshold;
    /// @notice The amount of LINK to reward an operator who
    /// raises an alert in the priority period.
    uint256 maxAlertingRewardAmount;
    /// @notice The minimum number of node operators required to initialize the
    /// staking pool.
    uint256 minInitialOperatorCount;
    /// @notice The minimum reward duration after pool config updates and pool
    /// reward extensions
    uint256 minRewardDuration;
    /// @notice The duration of earned rewards to slash when an alert is raised
    uint256 slashableDuration;
    /// @notice Used to calculate delegated stake amount
    /// = amount / delegation rate denominator = 100% / 100 = 1%
    uint256 delegationRateDenominator;
  }

  /// @notice The amount to divide an alerter's stake amount when
  /// calculating their reward for raising an alert.
  uint256 private constant ALERTING_REWARD_STAKED_AMOUNT_DENOMINATOR = 5;

  LinkTokenInterface private immutable i_LINK;
  StakingPoolLib.Pool private s_pool;
  RewardLib.Reward private s_reward;
  /// @notice The ETH USD feed that alerters can raise alerts for.
  AggregatorV3Interface private immutable i_monitoredFeed;
  /// @notice The proposed address stakers will migrate funds to
  address private s_proposedMigrationTarget;
  /// @notice The timestamp of when the migration target was proposed at
  uint256 private s_proposedMigrationTargetAt;
  /// @notice The address stakers can migrate their funds to
  address private s_migrationTarget;
  /// @notice The round ID of the last feed round an alert was raised
  uint256 private s_lastAlertedRoundId;
  /// @notice The merkle root of the merkle tree generated from the list
  /// of staker addresses with early acccess.
  bytes32 private s_merkleRoot;
  /// @notice The number of seconds until the feed is considered stale
  /// and the priority period begins.
  uint256 private immutable i_priorityPeriodThreshold;
  /// @notice The number of seconds until the priority period ends
  /// and the regular period begins.
  uint256 private immutable i_regularPeriodThreshold;
  /// @notice The amount of LINK to reward an operator who
  /// raises an alert in the priority period.
  uint256 private immutable i_maxAlertingRewardAmount;
  /// @notice The minimum stake amount that a node operator can stake
  uint256 private immutable i_minOperatorStakeAmount;
  /// @notice The minimum stake amount that a community staker can stake
  uint256 private immutable i_minCommunityStakeAmount;
  /// @notice The minimum number of node operators required to initialize the
  /// staking pool.
  uint256 private immutable i_minInitialOperatorCount;
  /// @notice The minimum reward duration after pool config updates and pool
  /// reward extensions
  uint256 private immutable i_minRewardDuration;
  /// @notice The duration of earned rewards to slash when an alert is raised
  uint256 private immutable i_slashableDuration;
  /// @notice Used to calculate delegated stake amount
  /// = amount / delegation rate denominator = 100% / 100 = 1%
  uint256 private immutable i_delegationRateDenominator;

  constructor(PoolConstructorParams memory params) ConfirmedOwner(msg.sender) {
    if (address(params.LINKAddress) == address(0)) revert InvalidZeroAddress();
    if (address(params.monitoredFeed) == address(0))
      revert InvalidZeroAddress();
    if (params.delegationRateDenominator == 0) revert InvalidDelegationRate();
    if (RewardLib.REWARD_PRECISION % params.delegationRateDenominator > 0)
      revert InvalidDelegationRate();
    if (params.regularPeriodThreshold <= params.priorityPeriodThreshold)
      revert InvalidRegularPeriodThreshold();
    if (params.minOperatorStakeAmount == 0)
      revert InvalidMinOperatorStakeAmount();
    if (params.minOperatorStakeAmount > params.initialMaxOperatorStakeAmount)
      revert InvalidMinOperatorStakeAmount();
    if (params.minCommunityStakeAmount > params.initialMaxCommunityStakeAmount)
      revert InvalidMinCommunityStakeAmount();
    if (params.maxAlertingRewardAmount > params.initialMaxOperatorStakeAmount)
      revert InvalidMaxAlertingRewardAmount();

    s_pool._setConfig(
      params.initialMaxPoolSize,
      params.initialMaxCommunityStakeAmount,
      params.initialMaxOperatorStakeAmount
    );
    i_LINK = params.LINKAddress;
    i_monitoredFeed = params.monitoredFeed;
    i_priorityPeriodThreshold = params.priorityPeriodThreshold;
    i_regularPeriodThreshold = params.regularPeriodThreshold;
    i_maxAlertingRewardAmount = params.maxAlertingRewardAmount;
    i_minOperatorStakeAmount = params.minOperatorStakeAmount;
    i_minCommunityStakeAmount = params.minCommunityStakeAmount;
    i_minInitialOperatorCount = params.minInitialOperatorCount;
    i_minRewardDuration = params.minRewardDuration;
    i_slashableDuration = params.slashableDuration;
    i_delegationRateDenominator = params.delegationRateDenominator;
  }

  // =======================
  // TypeAndVersionInterface
  // =======================

  /// @inheritdoc TypeAndVersionInterface
  function typeAndVersion() external pure override returns (string memory) {
    return 'Staking 0.1.0';
  }

  // =================
  // IMerkleAccessController
  // =================

  /// @inheritdoc IMerkleAccessController
  function hasAccess(address staker, bytes32[] memory proof)
    external
    view
    override
    returns (bool)
  {
    if (s_merkleRoot == bytes32(0)) return true;
    return
      MerkleProof.verify(proof, s_merkleRoot, keccak256(abi.encode(staker)));
  }

  /// @inheritdoc IMerkleAccessController
  function setMerkleRoot(bytes32 newMerkleRoot) external override onlyOwner {
    s_merkleRoot = newMerkleRoot;
    emit MerkleRootChanged(newMerkleRoot);
  }

  /// @inheritdoc IMerkleAccessController
  function getMerkleRoot() external view override returns (bytes32) {
    return s_merkleRoot;
  }

  // =============
  // IStakingOwner
  // =============

  /// @inheritdoc IStakingOwner
  function setPoolConfig(
    uint256 maxPoolSize,
    uint256 maxCommunityStakeAmount,
    uint256 maxOperatorStakeAmount
  ) external override(IStakingOwner) onlyOwner whenActive {
    s_pool._setConfig(
      maxPoolSize,
      maxCommunityStakeAmount,
      maxOperatorStakeAmount
    );

    s_reward._updateDuration(
      maxPoolSize,
      s_pool._getTotalStakedAmount(),
      uint256(s_reward.base.rate),
      i_minRewardDuration,
      getAvailableReward(),
      getTotalDelegatedAmount()
    );
  }

  /// @inheritdoc IStakingOwner
  function setFeedOperators(address[] calldata operators)
    external
    override(IStakingOwner)
    onlyOwner
  {
    s_pool._setFeedOperators(operators);
  }

  /// @inheritdoc IStakingOwner
  function start(uint256 amount, uint256 initialRewardRate)
    external
    override(IStakingOwner)
    onlyOwner
  {
    if (s_merkleRoot == bytes32(0)) revert MerkleRootNotSet();

    s_pool._open(i_minInitialOperatorCount);

    // We need to transfer LINK balance before we initialize the reward to
    // calculate the new reward expiry timestamp.
    i_LINK.transferFrom(msg.sender, address(this), amount);

    s_reward._initialize(
      uint256(s_pool.limits.maxPoolSize),
      initialRewardRate,
      i_minRewardDuration,
      getAvailableReward()
    );
  }

  /// @inheritdoc IStakingOwner
  function conclude() external override(IStakingOwner) onlyOwner whenActive {
    s_reward._release(
      s_pool._getTotalStakedAmount(),
      getTotalDelegatedAmount()
    );

    s_pool._close();
  }

  /// @inheritdoc IStakingOwner
  function addReward(uint256 amount)
    external
    override(IStakingOwner)
    onlyOwner
    whenActive
  {
    // We need to transfer LINK balance before we recalculate the reward expiry
    // timestamp so the new amount is accounted for.
    i_LINK.transferFrom(msg.sender, address(this), amount);

    s_reward._updateDuration(
      uint256(s_pool.limits.maxPoolSize),
      s_pool._getTotalStakedAmount(),
      uint256(s_reward.base.rate),
      i_minRewardDuration,
      getAvailableReward(),
      getTotalDelegatedAmount()
    );

    emit RewardLib.RewardAdded(amount);
  }

  /// @inheritdoc IStakingOwner
  function withdrawUnusedReward()
    external
    override(IStakingOwner)
    onlyOwner
    whenInactive
  {
    uint256 unusedRewards = getAvailableReward() -
      uint256(s_reward.reserved.base) -
      uint256(s_reward.reserved.delegated);
    emit RewardLib.RewardWithdrawn(unusedRewards);

    // msg.sender is the owner address as only the owner can call this function
    i_LINK.transfer(msg.sender, unusedRewards);
  }

  /// @dev Required conditions for adding operators:
  /// - Operators can only be added to the pool if they have no prior stake.
  /// - Operators can only be readded to the pool if they have no removed
  /// stake.
  /// - Operators cannot be added to the pool after staking ends (either through
  /// conclusion or through reward expiry).
  /// @inheritdoc IStakingOwner
  function addOperators(address[] calldata operators)
    external
    override(IStakingOwner)
    onlyOwner
  {
    // If reward was initialized (meaning the pool was active) but the pool is
    // no longer active we want to prevent adding new operators.
    if (s_reward.startTimestamp > 0 && !isActive())
      revert StakingPoolLib.InvalidPoolStatus(false, true);

    s_pool._addOperators(operators);
  }

  /// @inheritdoc IStakingOwner
  function removeOperators(address[] calldata operators)
    external
    override(IStakingOwner)
    onlyOwner
    whenActive
  {
    // Accumulate delegation rewards before removing operators as this affects
    // rewards that are distributed to remaining operators.
    s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());

    for (uint256 i; i < operators.length; i++) {
      address operator = operators[i];
      StakingPoolLib.Staker memory staker = s_pool.stakers[operator];

      if (!staker.isOperator)
        revert StakingPoolLib.OperatorDoesNotExist(operator);

      // Operator must not be on the feed
      if (staker.isFeedOperator)
        revert StakingPoolLib.OperatorIsAssignedToFeed(operator);

      uint256 principal = staker.stakedAmount;
      // An operator with stake is a delegate
      if (principal > 0) {
        // The operator's rewards are forfeited when they are removed
        // Unreserve operator's earned base reward
        s_reward.reserved.base -= getBaseReward(operator)._toUint96();
        // Unreserve operator's future base reward
        s_reward.reserved.base -= s_reward
          ._calculateReward(principal, s_reward._getRemainingDuration())
          ._toUint96();

        // Unreserve operator's earned delegation reward. We don't need to
        // unreserve future delegation rewards because they will be split by
        // other operators.
        s_reward.reserved.delegated -= getDelegationReward(operator)
          ._toUint96();

        s_reward.delegated.delegatesCount -= 1;
        delete s_pool.stakers[operator].stakedAmount;
        uint96 castPrincipal = principal._toUint96();
        s_pool.state.totalOperatorStakedAmount -= castPrincipal;
        // Only the operator's principal is withdrawable after they are removed
        s_pool.stakers[operator].removedStakeAmount = castPrincipal;
        s_pool.totalOperatorRemovedAmount += castPrincipal;

        // We need to reset operator's missed base rewards in case they decide
        // to stake as a community staker using the same address. It's fine to
        // not reset missed delegated rewards, because a removed operator
        // cannot be re-added as operator again.
        delete s_reward.missed[operator].base;
      }

      s_pool.stakers[operator].isOperator = false;
      emit StakingPoolLib.OperatorRemoved(operator, principal);
    }

    s_pool.state.operatorsCount -= operators.length._toUint8();
  }

  /// @inheritdoc IStakingOwner
  function changeRewardRate(uint256 newRate)
    external
    override
    onlyOwner
    whenActive
  {
    if (newRate == 0) revert();

    uint256 totalDelegatedAmount = getTotalDelegatedAmount();

    s_reward._accumulateDelegationRewards(totalDelegatedAmount);
    s_reward._accumulateBaseRewards();
    s_reward._updateDuration(
      uint256(s_pool.limits.maxPoolSize),
      s_pool._getTotalStakedAmount(),
      newRate,
      i_minRewardDuration,
      getAvailableReward(),
      totalDelegatedAmount
    );

    emit RewardLib.RewardRateChanged(newRate);
  }

  /// @inheritdoc IStakingOwner
  function emergencyPause() external override(IStakingOwner) onlyOwner {
    _pause();
  }

  /// @inheritdoc IStakingOwner
  function emergencyUnpause() external override(IStakingOwner) onlyOwner {
    _unpause();
  }

  /// @inheritdoc IStakingOwner
  function getFeedOperators()
    external
    view
    override(IStakingOwner)
    returns (address[] memory)
  {
    return s_pool.feedOperators;
  }

  // ===========
  // IMigratable
  // ===========

  /// @inheritdoc IMigratable
  function getMigrationTarget()
    external
    view
    override(IMigratable)
    returns (address)
  {
    return s_migrationTarget;
  }

  /// @inheritdoc IMigratable
  function proposeMigrationTarget(address migrationTarget)
    external
    override(IMigratable)
    onlyOwner
  {
    if (
      migrationTarget.code.length == 0 ||
      migrationTarget == address(this) ||
      s_proposedMigrationTarget == migrationTarget ||
      s_migrationTarget == migrationTarget ||
      !IERC165(migrationTarget).supportsInterface(this.onTokenTransfer.selector)
    ) revert InvalidMigrationTarget();

    s_migrationTarget = address(0);
    s_proposedMigrationTarget = migrationTarget;
    s_proposedMigrationTargetAt = block.timestamp;
    emit MigrationTargetProposed(migrationTarget);
  }

  /// @inheritdoc IMigratable
  function acceptMigrationTarget() external override(IMigratable) onlyOwner {
    if (s_proposedMigrationTarget == address(0))
      revert InvalidMigrationTarget();

    if (block.timestamp < (uint256(s_proposedMigrationTargetAt) + 7 days))
      revert AccessForbidden();

    s_migrationTarget = s_proposedMigrationTarget;
    s_proposedMigrationTarget = address(0);
    emit MigrationTargetAccepted(s_migrationTarget);
  }

  /// @inheritdoc IMigratable
  function migrate(bytes calldata data)
    external
    override(IMigratable)
    whenInactive
  {
    if (s_migrationTarget == address(0)) revert InvalidMigrationTarget();

    (uint256 amount, uint256 baseReward, uint256 delegationReward) = _exit(
      msg.sender
    );

    emit Migrated(msg.sender, amount, baseReward, delegationReward, data);

    i_LINK.transferAndCall(
      s_migrationTarget,
      uint256(amount + baseReward + delegationReward),
      abi.encode(msg.sender, data)
    );
  }

  // =================
  // IAlertsController
  // =================

  /// @inheritdoc IAlertsController
  function raiseAlert() external override(IAlertsController) whenActive {
    uint256 stakedAmount = getStake(msg.sender);
    if (stakedAmount == 0) revert AccessForbidden();

    (uint256 roundId, , , uint256 lastFeedUpdatedAt, ) = i_monitoredFeed
      .latestRoundData();

    if (roundId == s_lastAlertedRoundId) revert AlertAlreadyExists(roundId);

    if (block.timestamp < lastFeedUpdatedAt + i_priorityPeriodThreshold)
      revert AlertInvalid();

    bool isInPriorityPeriod = block.timestamp <
      lastFeedUpdatedAt + i_regularPeriodThreshold;

    if (isInPriorityPeriod && !s_pool._isOperator(msg.sender))
      revert AlertInvalid();

    s_lastAlertedRoundId = roundId;

    // There is a risk that this might get us below the total amount of
    // reserved if the reward amount slashed is greater than LINK
    // balance in the pool.  This is an extreme edge case that will only occur
    /// if an alert is raised many times such that it completely depletes the
    // available rewards in the pool.  As this is an unlikely scenario, the
    // contract avoids adding an extra check to minimize gas costs.
    // There is a similar edge case when the total slashed amount is less than
    // the alerting reward. This can happen because slashed amounts are capped to
    // earned rewards so far. The result is a net outflow of rewards from the
    // staking pool up to the max alerting reward amount in the worst case.
    // This is acceptable and in practice has little to no impact to staking.
    uint256 rewardAmount = _calculateAlertingRewardAmount(
      stakedAmount,
      isInPriorityPeriod
    );

    emit AlertRaised(msg.sender, roundId, rewardAmount);

    // We need to transfer the rewards out before recalculating the new reward
    // expiry timestamp
    i_LINK.transfer(msg.sender, rewardAmount);

    s_reward._slashOnFeedOperators(
      i_minOperatorStakeAmount,
      i_slashableDuration,
      s_pool.feedOperators,
      s_pool.stakers,
      getTotalDelegatedAmount()
    );

    s_reward._updateDuration(
      uint256(s_pool.limits.maxPoolSize),
      s_pool._getTotalStakedAmount(),
      uint256(s_reward.base.rate),
      0,
      getAvailableReward(),
      getTotalDelegatedAmount()
    );
  }

  /// @inheritdoc IAlertsController
  function canAlert(address alerter)
    external
    view
    override(IAlertsController)
    returns (bool)
  {
    if (getStake(alerter) == 0) return false;
    if (!isActive()) return false;
    (uint256 roundId, , , uint256 updatedAt, ) = i_monitoredFeed
      .latestRoundData();
    if (roundId == s_lastAlertedRoundId) return false;

    // nobody can (feed is not stale)
    if (block.timestamp < updatedAt + i_priorityPeriodThreshold) return false;

    // all stakers can (regular alerters)
    if (block.timestamp >= updatedAt + i_regularPeriodThreshold) return true;
    return s_pool._isOperator(alerter); // only operators can (priority alerters)
  }

  // ========
  // IStaking
  // ========

  /// @inheritdoc IStaking
  function unstake() external override(IStaking) whenInactive {
    (uint256 amount, uint256 baseReward, uint256 delegationReward) = _exit(
      msg.sender
    );

    emit Unstaked(msg.sender, amount, baseReward, delegationReward);
    i_LINK.transfer(msg.sender, amount + baseReward + delegationReward);
  }

  /// @inheritdoc IStaking
  function withdrawRemovedStake() external override(IStaking) whenInactive {
    uint256 amount = s_pool.stakers[msg.sender].removedStakeAmount;
    if (amount == 0) revert StakingPoolLib.StakeNotFound(msg.sender);

    s_pool.totalOperatorRemovedAmount -= amount;
    delete s_pool.stakers[msg.sender].removedStakeAmount;
    emit Unstaked(msg.sender, amount, 0, 0);
    i_LINK.transfer(msg.sender, amount);
  }

  /// @inheritdoc IStaking
  function getStake(address staker)
    public
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool.stakers[staker].stakedAmount;
  }

  /// @inheritdoc IStaking
  function isOperator(address staker)
    external
    view
    override(IStaking)
    returns (bool)
  {
    return s_pool._isOperator(staker);
  }

  /// @inheritdoc IStaking
  function isActive() public view override(IStaking) returns (bool) {
    return s_pool.state.isOpen && !s_reward._isDepleted();
  }

  /// @inheritdoc IStaking
  function getMaxPoolSize() external view override(IStaking) returns (uint256) {
    return uint256(s_pool.limits.maxPoolSize);
  }

  /// @inheritdoc IStaking
  function getCommunityStakerLimits()
    external
    view
    override(IStaking)
    returns (uint256, uint256)
  {
    return (
      i_minCommunityStakeAmount,
      uint256(s_pool.limits.maxCommunityStakeAmount)
    );
  }

  /// @inheritdoc IStaking
  function getOperatorLimits()
    external
    view
    override(IStaking)
    returns (uint256, uint256)
  {
    return (
      i_minOperatorStakeAmount,
      uint256(s_pool.limits.maxOperatorStakeAmount)
    );
  }

  /// @inheritdoc IStaking
  function getRewardTimestamps()
    external
    view
    override(IStaking)
    returns (uint256, uint256)
  {
    return (uint256(s_reward.startTimestamp), uint256(s_reward.endTimestamp));
  }

  /// @inheritdoc IStaking
  function getRewardRate() external view override(IStaking) returns (uint256) {
    return uint256(s_reward.base.rate);
  }

  /// @inheritdoc IStaking
  function getDelegationRateDenominator()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return i_delegationRateDenominator;
  }

  /// @inheritdoc IStaking
  function getAvailableReward()
    public
    view
    override(IStaking)
    returns (uint256)
  {
    return
      i_LINK.balanceOf(address(this)) -
      s_pool._getTotalStakedAmount() -
      s_pool.totalOperatorRemovedAmount;
  }

  /// @inheritdoc IStaking
  function getBaseReward(address staker)
    public
    view
    override(IStaking)
    returns (uint256)
  {
    uint256 stake = s_pool.stakers[staker].stakedAmount;
    if (stake == 0) return 0;

    if (s_pool._isOperator(staker)) {
      return s_reward._getOperatorEarnedBaseRewards(staker, stake);
    }

    return
      s_reward._calculateAccruedBaseRewards(
        RewardLib._getNonDelegatedAmount(stake, i_delegationRateDenominator)
      ) - uint256(s_reward.missed[staker].base);
  }

  /// @inheritdoc IStaking
  function getDelegationReward(address staker)
    public
    view
    override(IStaking)
    returns (uint256)
  {
    StakingPoolLib.Staker memory stakerAccount = s_pool.stakers[staker];
    if (!stakerAccount.isOperator) return 0;
    if (stakerAccount.stakedAmount == 0) return 0;
    return
      s_reward._getOperatorEarnedDelegatedRewards(
        staker,
        getTotalDelegatedAmount()
      );
  }

  /// @inheritdoc IStaking
  function getTotalDelegatedAmount()
    public
    view
    override(IStaking)
    returns (uint256)
  {
    return
      RewardLib._getDelegatedAmount(
        s_pool.state.totalCommunityStakedAmount,
        i_delegationRateDenominator
      );
  }

  /// @inheritdoc IStaking
  function getDelegatesCount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return uint256(s_reward.delegated.delegatesCount);
  }

  /// @inheritdoc IStaking
  function getTotalStakedAmount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool._getTotalStakedAmount();
  }

  /// @inheritdoc IStaking
  function getTotalCommunityStakedAmount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool.state.totalCommunityStakedAmount;
  }

  /// @inheritdoc IStaking
  function getTotalRemovedAmount()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_pool.totalOperatorRemovedAmount;
  }

  /// @inheritdoc IStaking
  function getEarnedBaseRewards()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return
      s_reward._getEarnedBaseRewards(
        s_pool._getTotalStakedAmount(),
        getTotalDelegatedAmount()
      );
  }

  /// @inheritdoc IStaking
  function getEarnedDelegationRewards()
    external
    view
    override(IStaking)
    returns (uint256)
  {
    return s_reward._getEarnedDelegationRewards(getTotalDelegatedAmount());
  }

  /// @inheritdoc IStaking
  function isPaused() external view override(IStaking) returns (bool) {
    return paused();
  }

  /// @inheritdoc IStaking
  function getChainlinkToken()
    public
    view
    override(IStaking)
    returns (address)
  {
    return address(i_LINK);
  }

  /// @inheritdoc IStaking
  function getMonitoredFeed() external view override returns (address) {
    return address(i_monitoredFeed);
  }

  /**
   * @notice Called when LINK is sent to the contract via `transferAndCall`
   * @param sender Address of the sender
   * @param amount Amount of LINK sent (specified in wei)
   * @param data Optional payload containing a Staking Allowlist Merkle proof
   */
  function onTokenTransfer(
    address sender,
    uint256 amount,
    bytes memory data
  ) external validateFromLINK whenNotPaused whenActive {
    if (amount < RewardLib.REWARD_PRECISION)
      revert StakingPoolLib.InsufficientStakeAmount(RewardLib.REWARD_PRECISION);

    // TL;DR: Reward calculation and delegation logic requires precise numbers
    // to avoid cumulative rounding errors.
    // Long explanation:
    // When users stake amounts that are rounded down to 0 after dividing
    // by the delegation rate denominator, not enough rewards are reserved for
    // the user. When the user then stakes enough times, small rounding errors
    // accumulate. This causes an integer underflow when unreserving rewards because
    // the total delegated amount returns a larger number than what individual
    // reserved amounts sum up to.
    uint256 remainder = amount % RewardLib.REWARD_PRECISION;
    if (remainder > 0) {
      amount -= remainder;
      i_LINK.transfer(sender, remainder);
    }

    if (s_pool._isOperator(sender)) {
      _stakeAsOperator(sender, amount);
    } else {
      // If a Merkle root is set, the sender should
      // prove that they are part of the merkle tree
      if (s_merkleRoot != bytes32(0)) {
        if (data.length == 0) revert AccessForbidden();
        if (
          !MerkleProof.verify(
            abi.decode(data, (bytes32[])),
            s_merkleRoot,
            keccak256(abi.encode(sender))
          )
        ) revert AccessForbidden();
      }
      _stakeAsCommunityStaker(sender, amount);
    }
  }

  // =======
  // Private
  // =======

  /// @notice Helper function for when a community staker enters the pool
  /// @param staker The staker address
  /// @param amount The amount of principal staked
  /// @dev When an operator is removed they can stake as a community staker.
  /// We allow that because the alternative (checking for removed stake before
  /// staking) is going to unnecessarily increase gas costs in 99.99% of the
  /// cases.
  function _stakeAsCommunityStaker(address staker, uint256 amount) private {
    uint256 currentStakedAmount = s_pool.stakers[staker].stakedAmount;
    uint256 newStakedAmount = currentStakedAmount + amount;
    // Check that the amount is greater than or equal to the minimum required
    if (newStakedAmount < i_minCommunityStakeAmount)
      revert StakingPoolLib.InsufficientStakeAmount(i_minCommunityStakeAmount);

    // Check that the amount is less than or equal to the maximum allowed
    uint256 maxCommunityStakeAmount = uint256(
      s_pool.limits.maxCommunityStakeAmount
    );
    if (newStakedAmount > maxCommunityStakeAmount)
      revert StakingPoolLib.ExcessiveStakeAmount(
        maxCommunityStakeAmount - currentStakedAmount
      );

    // Check if the amount supplied increases the total staked amount above
    // the maximum pool size
    uint256 remainingPoolSpace = s_pool._getRemainingPoolSpace();
    if (amount > remainingPoolSpace)
      revert StakingPoolLib.ExcessiveStakeAmount(remainingPoolSpace);

    s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());
    uint256 extraNonDelegatedAmount = RewardLib._getNonDelegatedAmount(
      amount,
      i_delegationRateDenominator
    );
    s_reward.missed[staker].base += s_reward
      ._calculateAccruedBaseRewards(extraNonDelegatedAmount)
      ._toUint96();
    s_reward._reserve(
      extraNonDelegatedAmount,
      RewardLib._getDelegatedAmount(amount, i_delegationRateDenominator)
    );
    s_pool.state.totalCommunityStakedAmount += amount._toUint96();
    s_pool.stakers[staker].stakedAmount = newStakedAmount._toUint96();
    emit Staked(staker, amount, newStakedAmount);
  }

  /// @notice Helper function for when an operator enters the pool
  /// @dev Function skips validating whether or not the operator stake
  /// amount will cause the total stake amount to exceed the maximum pool size.
  /// This is because the pool already reserves a fixed amount of space
  /// for each operator meaning that an operator staking cannot cause the
  /// total stake amount to exceed the maximum pool size.  Each operator
  /// receives a reserved stake amount equal to the maxOperatorStakeAmount.
  /// This is done by deducting operatorCount * maxOperatorStakeAmount from the
  /// remaining pool space available for staking.
  /// @param staker The staker address
  /// @param amount The amount of principal staked
  function _stakeAsOperator(address staker, uint256 amount) private {
    StakingPoolLib.Staker storage operator = s_pool.stakers[staker];
    uint256 currentStakedAmount = operator.stakedAmount;
    uint256 newStakedAmount = currentStakedAmount + amount;

    // Check that the amount is greater than or equal to the minimum required
    if (newStakedAmount < i_minOperatorStakeAmount)
      revert StakingPoolLib.InsufficientStakeAmount(i_minOperatorStakeAmount);

    // Check that the amount is less than or equal to the maximum allowed
    uint256 maxOperatorStakeAmount = uint256(
      s_pool.limits.maxOperatorStakeAmount
    );
    if (newStakedAmount > maxOperatorStakeAmount)
      revert StakingPoolLib.ExcessiveStakeAmount(
        maxOperatorStakeAmount - currentStakedAmount
      );

    // On first stake
    if (currentStakedAmount == 0) {
      s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());
      uint8 delegatesCount = s_reward.delegated.delegatesCount;

      // We are doing this check to unreserve any unused delegated rewards
      // prior to the first operator staking. After the rewards are unreserved
      // we reset the accumulated value so it doesn't count towards missed
      // rewards.
      // There is a known edge-case where, if no operator stakes throughout the
      // duration of the pool, we wouldn't unreserve unused delegation rewards.
      // In practice this shouldn't happen and, if it does, there are
      // operational workarounds to unreserve those rewards.
      if (delegatesCount == 0) {
        s_reward.reserved.delegated -= s_reward.delegated.cumulativePerDelegate;
        delete s_reward.delegated.cumulativePerDelegate;
      }

      s_reward.delegated.delegatesCount = delegatesCount + 1;

      s_reward.missed[staker].delegated = s_reward
        .delegated
        .cumulativePerDelegate;
    }

    s_reward.missed[staker].base += s_reward
      ._calculateAccruedBaseRewards(amount)
      ._toUint96();
    s_pool.state.totalOperatorStakedAmount += amount._toUint96();
    s_reward._reserve(amount, 0);
    s_pool.stakers[staker].stakedAmount = newStakedAmount._toUint96();
    emit Staked(staker, amount, newStakedAmount);
  }

  /// @notice Helper function when staker exits the pool
  /// @param staker The staker address
  function _exit(address staker)
    private
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    StakingPoolLib.Staker memory stakerAccount = s_pool.stakers[staker];
    if (stakerAccount.stakedAmount == 0)
      revert StakingPoolLib.StakeNotFound(staker);

    // If the pool isOpen that means that we haven't concluded it and stakers
    // got here because the reward depleted. In that case, the first user to
    // unstake will accumulate delegation and base rewards to save on cost for
    // others.
    if (s_pool.state.isOpen) {
      // Accumulate base and delegation rewards before unreserving rewards to
      // save gas costs. We can use the accumulated reward per micro LINK and
      // accumulated delegation reward to simplify reward calculations.
      s_reward._accumulateDelegationRewards(getTotalDelegatedAmount());
      s_reward._accumulateBaseRewards();
      delete s_pool.state.isOpen;
    }

    if (stakerAccount.isOperator) {
      s_pool.state.totalOperatorStakedAmount -= stakerAccount.stakedAmount;

      uint256 baseReward = s_reward._calculateConcludedBaseRewards(
        stakerAccount.stakedAmount,
        staker
      );
      uint256 delegationReward = uint256(
        s_reward.delegated.cumulativePerDelegate
      ) - uint256(s_reward.missed[staker].delegated);

      delete s_pool.stakers[staker].stakedAmount;
      s_reward.reserved.base -= baseReward._toUint96();
      s_reward.reserved.delegated -= delegationReward._toUint96();
      return (stakerAccount.stakedAmount, baseReward, delegationReward);
    } else {
      s_pool.state.totalCommunityStakedAmount -= stakerAccount.stakedAmount;

      uint256 baseReward = s_reward._calculateConcludedBaseRewards(
        RewardLib._getNonDelegatedAmount(
          stakerAccount.stakedAmount,
          i_delegationRateDenominator
        ),
        staker
      );
      delete s_pool.stakers[staker].stakedAmount;
      s_reward.reserved.base -= baseReward._toUint96();
      return (stakerAccount.stakedAmount, baseReward, 0);
    }
  }

  /// @notice Calculates the reward amount an alerter will receive for raising
  /// a successful alert in the current alerting period.
  /// @param stakedAmount Amount of LINK staked by the alerter
  /// @param isInPriorityPeriod True if it is currently in the priority period
  /// @return rewardAmount Amount of LINK rewards to be paid to the alerter
  function _calculateAlertingRewardAmount(
    uint256 stakedAmount,
    bool isInPriorityPeriod
  ) private view returns (uint256) {
    if (isInPriorityPeriod) return i_maxAlertingRewardAmount;
    return
      Math.min(
        stakedAmount / ALERTING_REWARD_STAKED_AMOUNT_DENOMINATOR,
        i_maxAlertingRewardAmount
      );
  }

  // =========
  // Modifiers
  // =========

  /// @dev Having a private function for the modifer saves on the contract size
  function _isActive() private view {
    if (!isActive()) revert StakingPoolLib.InvalidPoolStatus(false, true);
  }

  /// @dev Reverts if the staking pool is inactive (not open for staking or
  /// expired)
  modifier whenActive() {
    _isActive();

    _;
  }

  /// @dev Reverts if the staking pool is active (open for staking)
  modifier whenInactive() {
    if (isActive()) revert StakingPoolLib.InvalidPoolStatus(true, false);

    _;
  }

  /// @dev Reverts if not sent from the LINK token
  modifier validateFromLINK() {
    if (msg.sender != getChainlinkToken()) revert SenderNotLinkToken();

    _;
  }
}