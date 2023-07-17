// SPDX-License-Identifier: GPL-3.0-only
pragma solidity =0.7.6;
pragma abicoder v2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

abstract contract FundablePool is AccessControl {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  struct RewardSchedule {
    // [eR] Amount of reward token contributed. (immutable)
    uint256 amount;
    // [seconds] Duration of funding round (immutable)
    uint256 duration;
    // [seconds] Epoch timestamp for start time (immutable)
    uint256 start;
    // [eR] Amount still locked
    uint256 amountLocked;
    // [seconds] Last updated epoch timestamp
    uint256 updated;
  }

  /* ========== CONSTANTS ========== */
  bytes32 public constant FUNDER_ROLE = keccak256("FUNDER_ROLE");

  /* ========== STATE VARIABLES ========== */
  IERC20 public immutable rewardToken;

  /// @notice [eR] {cached} total reward amount <=> rewardToken.balanceOf
  uint256 public totalRewardAmount;

  /// @notice [eR] {cached} locked reward amount
  uint256 public lockedRewardAmount;

  /// @dev All non-expired reward schedules
  RewardSchedule[] internal _rewardSchedules;

  /* ========== CONSTRUCTOR ========== */
  /**
   * @notice Construct a new FundablePool
   */
  constructor(address _funder, address _rewardToken) {
    rewardToken = IERC20(_rewardToken);
    _setupRole(FUNDER_ROLE, _funder);
  }

  /* ========== EVENTS ========== */
  event RewardsFunded(uint256 amount, uint256 start, uint256 duration);
  event RewardsUnlocked(uint256 amount);
  event RewardsPaid(address indexed user, uint256 reward);
  event RewardsExpired(uint256 amount, uint256 start);

  /* ========== MODIFIERS ========== */

  modifier onlyFunder() {
    require(hasRole(FUNDER_ROLE, msg.sender), "FundablePool/OnlyFunder");
    _;
  }

  /* ========== VIEWS ========== */

  /**
   * @notice All active/pending reward schedules
   */
  function rewardSchedules() external view returns (RewardSchedule[] memory) {
    return _rewardSchedules;
  }

  /**
   * @notice Rewards that are unlocked
   */
  function unlockedRewardAmount() public view returns (uint256) {
    return totalRewardAmount.sub(lockedRewardAmount);
  }

  /**
   * @notice Rewards that are pending unlock (will be unlocked on next update)
   */
  function pendingRewardAmount(uint256 timestamp)
    public
    view
    returns (uint256 unlockedRewards)
  {
    for (uint256 i = 0; i < _rewardSchedules.length; i++) {
      unlockedRewards = unlockedRewards.add(unlockable(i, timestamp));
    }
  }

  /**
   * @notice Compute the number of unlockable rewards for the given RewardSchedule
   * @param idx index of RewardSchedule
   * @return the number of unlockable rewards
   */
  function unlockable(uint256 idx, uint256 timestamp)
    public
    view
    returns (uint256)
  {
    RewardSchedule memory rs = _rewardSchedules[idx];

    // If still to start, then 0 unlocked
    if (timestamp <= rs.start) {
      return 0;
    }
    // If all used of rs used up, there is 0 left to unlock
    if (rs.amountLocked == 0) {
      return 0;
    }

    // if there is dust left, use it up.
    if (timestamp >= rs.start.add(rs.duration)) {
      return rs.amountLocked;
    }

    // N.B. rs.update >= rs.start;
    // => rs.start <= timeElapsed < rs.start + rs.duration
    uint256 timeElapsed = timestamp.sub(rs.updated);
    return timeElapsed.mul(rs.amount).div(rs.duration);
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /* ========== RESTRICTED FUNCTIONS ========== */

  /* ----- Funder ----- */

  /**
   * @notice Fund pool using locked up reward tokens for future distribution
   * @dev Assumes: onlyFunder
   * @param amount number of reward tokens to lock up as funding
   * @param duration period (seconds) over which funding will be unlocked
   * @param start time (seconds) at which funding begins to unlock
   */
  function _fund(
    uint256 amount,
    uint256 duration,
    uint256 start
  ) internal {
    require(duration != 0, "FundablePool/ZeroDuration");
    require(start >= block.timestamp, "FundablePool/HistoricFund");

    uint256 allowed =
      rewardToken.balanceOf(address(this)).sub(totalRewardAmount);

    require(allowed >= amount, "FundablePool/InsufficentBalance");

    // Update {cached} values
    totalRewardAmount = totalRewardAmount.add(amount);
    lockedRewardAmount = lockedRewardAmount.add(amount);

    // create new funding
    _rewardSchedules.push(
      RewardSchedule({
        amount: amount,
        amountLocked: amount,
        updated: start,
        start: start,
        duration: duration
      })
    );

    emit RewardsFunded(amount, start, duration);
  }

  /**
   * @notice Clean up stale reward schedules
   * @dev Assumes: onlyFunder
   */
  function _cleanRewardSchedules() internal {
    // check for stale reward schedules to expire
    uint256 removed = 0;
    // Gas will hit cap before this becomes an overflow problem
    uint256 originalSize = _rewardSchedules.length;
    for (uint256 i = 0; i < originalSize; i++) {
      uint256 idx = i - removed;
      RewardSchedule storage funding = _rewardSchedules[idx];

      if (
        unlockable(idx, block.timestamp) == 0 &&
        block.timestamp >= funding.start.add(funding.duration)
      ) {
        emit RewardsExpired(funding.amount, funding.start);

        // remove at idx by copying last element here, then popping off last
        // (we don't care about order)
        _rewardSchedules[idx] = _rewardSchedules[_rewardSchedules.length - 1];
        _rewardSchedules.pop();
        removed++;
      }
    }
  }

  /* ========== INTERNAL FUNCTIONS ========== */

  /**
   * @dev Unlocks reward tokens based on funding schedules
   * @return unlockedRewards number of rewards unlocked
   */
  function _unlockRewards() internal returns (uint256 unlockedRewards) {
    // get unlockable rewards for each funding schedule
    for (uint256 i = 0; i < _rewardSchedules.length; i++) {
      uint256 unlockableRewardAtIdx = unlockable(i, block.timestamp);
      RewardSchedule storage funding = _rewardSchedules[i];
      if (unlockableRewardAtIdx != 0) {
        funding.amountLocked = funding.amountLocked.sub(unlockableRewardAtIdx);
        funding.updated = block.timestamp;
        unlockedRewards = unlockedRewards.add(unlockableRewardAtIdx);
      }
    }

    if (unlockedRewards != 0) {
      // Update {cached} lockedRewardAmount
      lockedRewardAmount = lockedRewardAmount.sub(unlockedRewards);
      emit RewardsUnlocked(unlockedRewards);
    }
  }

  /**
   * @dev Distribute reward tokens to user
   *
   * Assumptions:
   * - `user` deserves this amount
   *
   * @param user address of user receiving reward
   * @param amount number of reward tokens to be distributed
   */
  function _distributeRewards(address user, uint256 amount) internal {
    assert(amount <= totalRewardAmount);

    // update {cached} totalRewardAmount
    totalRewardAmount = totalRewardAmount.sub(amount);

    rewardToken.safeTransfer(user, amount);
    emit RewardsPaid(user, amount);
  }
}