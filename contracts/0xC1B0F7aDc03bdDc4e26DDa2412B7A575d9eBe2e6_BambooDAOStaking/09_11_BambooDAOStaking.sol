// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Recoverable.sol";
import "./Generatable.sol";
import "./Array.sol";

struct Fee {
  uint128 numerator;
  uint128 denominator;
}

struct PendingPeriod {
  uint128 repeat;
  uint128 period;
}

struct PendingAmount {
  uint32 createdAt;
  uint112 fullAmount;
  uint112 claimedAmount;
  PendingPeriod pendingPeriod;
}

/**
 * @title Contract that adds auto-compounding staking functionalities with whitelist support
 * @author artpumpkin
 * @notice Stakes any ERC20 token in a auto-compounding way using this contract
 */
contract BambooDAOStaking is Ownable, Pausable, Generatable, Recoverable {
  using Array for uint256[];
  using SafeERC20 for IERC20;

  IERC20 private immutable _token;

  uint256 private constant YEAR = 365 days;

  uint152 public rewardRate;
  uint32 public rewardDuration = 12 weeks;
  uint32 private _rewardUpdatedAt = uint32(block.timestamp);
  uint32 public rewardFinishedAt;
  bool public whitelisted = false;
  mapping(address => bool) public isWhitelisted;

  uint256 private _totalStake;
  mapping(address => uint256) private _userStake;

  uint128 private _rewardPerToken;
  uint128 private _lastRewardPerTokenPaid;
  mapping(address => uint256) private _userRewardPerTokenPaid;

  Fee public fee = Fee(0, 1000);

  PendingPeriod public pendingPeriod = PendingPeriod({ repeat: 4, period: 7 days });
  mapping(address => uint256[]) private _userPendingIds;
  mapping(address => mapping(uint256 => PendingAmount)) private _userPending;

  /**
   * @param token_ The ERC20 token address to enable staking for
   */
  constructor(IERC20 token_) {
    _token = token_;
  }

  /**
   * @notice Computes the compounded total stake in real-time
   * @return totalStake The current compounded total stake
   */
  function totalStake() public view returns (uint256) {
    return _totalStake + _earned(_totalStake, _lastRewardPerTokenPaid);
  }

  /**
   * @notice Gets the current staking APY (4 decimals)
   * @return apy The current staking APY
   */
  function apy() external view returns (uint256) {
    if (block.timestamp > rewardFinishedAt || totalStake() == 0) {
      return 0;
    }

    return (rewardRate * YEAR * 100 * 100) / totalStake();
  }

  /**
   * @notice Converts targeted APY (4 decimals) to rewards to set
   * @param apy_ The targeted APY to convert
   * @return rewards The amount of rewards to set to match the targeted APY
   */
  function apyToAlphaRewards(uint256 apy_) external view returns (uint256) {
    return (totalStake() * rewardDuration * apy_) / (YEAR * 100 * 100);
  }

  /**
   * @notice Converts targeted APY (4 decimals) to rewards to increase/decrease
   * @dev This function can only be used if the reward duration isn't finished yet
   * @param apy_ The targeted APY to convert
   * @return rewards The amount of rewards to increase/decrease to match the targeted APY
   */
  function apyToDeltaRewards(uint256 apy_) external view returns (int256) {
    require(block.timestamp <= rewardFinishedAt, "reward duration finished");

    uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);

    int256 results = int256((totalStake() * rewardDuration * apy_) / (YEAR * 100 * 100)) - int256(remainingReward);

    return results >= 0 ? results : -results;
  }

  /**
   * @notice Gets the current rewards for a specific duration in seconds
   * @param duration_ The specific duration in seconds
   * @return rewards The rewards computed for the inputed duration
   */
  function rewardsForDuration(uint256 duration_) external view returns (uint256) {
    if (block.timestamp > rewardFinishedAt) {
      return 0;
    }

    return rewardRate * duration_;
  }

  /**
   * @notice Computes the compounded user stake in real-time
   * @param account_ The user address to use
   * @return userStake The current compounded user stake
   */
  function userStake(address account_) external view returns (uint256) {
    return _userStake[account_] + earned(account_);
  }

  /**
   * @notice Returns the user pending amount metadata
   * @param account_ The user address to use
   * @param index_ The user pending index to use
   * @return pendingAmount The user pending amount metadata
   */
  function userPending(address account_, uint256 index_) public view returns (PendingAmount memory) {
    uint256 id = _userPendingIds[account_][index_];
    return _userPending[account_][id];
  }

  /**
   * @notice Computes the user claimable pending percentage
   * @param account_ The user address to use
   * @param index_ The user pending index to use
   * @dev 18 decimals were used to not lose information
   * @return percentage The user claimable pending percentage
   */
  function userClaimablePendingPercentage(address account_, uint256 index_) external view returns (uint256) {
    PendingAmount memory pendingAmount = userPending(account_, index_);
    uint256 n = getClaimablePendingPortion(pendingAmount);
    return n >= pendingAmount.pendingPeriod.repeat ? 100 * 1e9 : (n * 100 * 1e9) / pendingAmount.pendingPeriod.repeat;
  }

  /**
   * @notice Returns the user pending ids
   * @param account_ The user address to use
   * @return ids The user pending ids
   */
  function userPendingIds(address account_) external view returns (uint256[] memory) {
    return _userPendingIds[account_];
  }

  /**
   * @notice Returns the last time rewards were updated
   * @return lastTimeRewardActiveAt A timestamp of the last time the update reward modifier was called
   */
  function lastTimeRewardActiveAt() public view returns (uint256) {
    return rewardFinishedAt > block.timestamp ? block.timestamp : rewardFinishedAt;
  }

  /**
   * @notice Returns the current reward per token value
   * @return rewardPerToken The accumulated reward per token value
   */
  function rewardPerToken() public view returns (uint256) {
    if (_totalStake == 0) {
      return _rewardPerToken;
    }

    return _rewardPerToken + ((lastTimeRewardActiveAt() - _rewardUpdatedAt) * rewardRate * 1e9) / _totalStake;
  }

  /**
   * @notice Returns the total rewards available
   * @return totalDurationReward The total expected rewards for the current reward duration
   */
  function totalDurationReward() external view returns (uint256) {
    return rewardRate * rewardDuration;
  }

  /**
   * @notice Returns the user earned rewards
   * @param account_ The user address to use
   * @return earned The user earned rewards
   */
  function earned(address account_) private view returns (uint256) {
    return _earned(_userStake[account_], _userRewardPerTokenPaid[account_]);
  }

  /**
   * @notice Returns the accumulated rewards for a given staking amount
   * @param stakeAmount_ The staked token amount
   * @param rewardPerTokenPaid_ The already paid reward per token
   * @return _earned The earned rewards based on a staking amount and the reward per token paid
   */
  function _earned(uint256 stakeAmount_, uint256 rewardPerTokenPaid_) internal view returns (uint256) {
    uint256 rewardPerTokenDiff = rewardPerToken() - rewardPerTokenPaid_;
    return (stakeAmount_ * rewardPerTokenDiff) / 1e9;
  }

  /**
   * @notice This modifier is used to update the rewards metadata for a specific account
   * @notice It is called for every user or owner interaction that changes the staking, the reward pool or the reward duration
   * @notice This is an extended modifier version of the Synthetix contract to support auto-compounding
   * @notice _rewardPerToken is accumulated every second
   * @notice _rewardUpdatedAt is updated for every interaction with this modifier
   * @param account_ The user address to use
   */
  modifier updateReward(address account_) {
    _rewardPerToken = uint128(rewardPerToken());
    _rewardUpdatedAt = uint32(lastTimeRewardActiveAt());

    // auto-compounding
    if (account_ != address(0)) {
      uint256 reward = earned(account_);

      _userRewardPerTokenPaid[account_] = _rewardPerToken;
      _lastRewardPerTokenPaid = _rewardPerToken;

      _userStake[account_] += reward;
      _totalStake += reward;
    }
    _;
  }

  /**
   * @notice This modifier is used to check whether the sender is whitelisted or not
   */
  modifier onlyWhitelist() {
    require(!whitelisted || isWhitelisted[msg.sender], "sender isn't whitelisted");
    _;
  }

  /**
   * @notice Sets the contract to support whitelisting or not
   * @param value_ Boolean value indicating whether to enable whitelisting or not
   */
  function setWhitelisted(bool value_) external onlyOwner {
    whitelisted = value_;

    emit WhitelistedSet(value_);
  }

  /**
   * @notice Sets an array of users to be whitelisted or not
   * @param users_ Users addresses
   * @param values_ Boolean values indicating whether the current user to be whitelisted or not
   */
  function setIsWhitelisted(address[] calldata users_, bool[] calldata values_) external onlyOwner {
    require(users_.length == values_.length, "users_ and values_ have different lengths");

    for (uint256 i = 0; i < users_.length; i++) {
      isWhitelisted[users_[i]] = values_[i];
    }

    emit IsWhitelistedSet(users_, values_);
  }

  /**
   * @notice Stakes an amount of the ERC20 token
   * @param amount_ The amount to stake
   */
  function stake(uint256 amount_) external whenNotPaused updateReward(msg.sender) onlyWhitelist {
    // checks
    require(amount_ > 0, "invalid input amount");

    // effects
    _totalStake += amount_;
    _userStake[msg.sender] += amount_;

    // interactions
    _token.safeTransferFrom(msg.sender, address(this), amount_);

    emit Staked(msg.sender, amount_);
  }

  /**
   * @notice Creates a new pending after withdrawal
   * @param amount_ The amount to create pending for
   */
  function createPending(uint256 amount_) internal {
    uint256 id = unique();
    _userPendingIds[msg.sender].push(id);
    _userPending[msg.sender][id] = PendingAmount({ createdAt: uint32(block.timestamp), fullAmount: uint112(amount_), claimedAmount: 0, pendingPeriod: pendingPeriod });

    emit PendingCreated(msg.sender, block.timestamp, amount_);
  }

  /**
   * @notice Cancels an existing pending
   * @param index_ The pending index to cancel
   */
  function cancelPending(uint256 index_) external whenNotPaused updateReward(msg.sender) {
    PendingAmount memory pendingAmount = userPending(msg.sender, index_);
    uint256 amount = pendingAmount.fullAmount - pendingAmount.claimedAmount;
    deletePending(index_);

    // effects
    _totalStake += amount;
    _userStake[msg.sender] += amount;

    emit PendingCanceled(msg.sender, pendingAmount.createdAt, pendingAmount.fullAmount);
  }

  /**
   * @notice Deletes an existing pending
   * @param index_ The pending index to delete
   */
  function deletePending(uint256 index_) internal {
    uint256[] storage ids = _userPendingIds[msg.sender];
    uint256 id = ids[index_];
    ids.remove(index_);
    delete _userPending[msg.sender][id];
  }

  /**
   * @notice Withdraws an amount of the ERC20 token
   * @notice When you withdraw a pending will be created for that amount
   * @notice You will be able to claim the pending for after an exact vesting period
   * @param amount_ The amount to withdraw
   */
  function _withdraw(uint256 amount_) internal {
    // effects
    _totalStake -= amount_;
    _userStake[msg.sender] -= amount_;

    createPending(amount_);

    emit Withdrawn(msg.sender, amount_);
  }

  /**
   * @notice Withdraws an amount of the ERC20 token
   * @param amount_ The amount to withdraw
   */
  function withdraw(uint256 amount_) external whenNotPaused updateReward(msg.sender) {
    // checks
    require(_userStake[msg.sender] > 0, "user has no active stake");
    require(amount_ > 0 && _userStake[msg.sender] >= amount_, "invalid input amount");

    // effects
    _withdraw(amount_);
  }

  /**
   * @notice Withdraws the full amount of the ERC20 token
   */
  function withdrawAll() external whenNotPaused updateReward(msg.sender) {
    // checks
    require(_userStake[msg.sender] > 0, "user has no active stake");

    // effects
    _withdraw(_userStake[msg.sender]);
  }

  /**
   * @notice Gets the user claimable pending portion
   * @param pendingAmount_ The pending amount metadata to use
   */
  function getClaimablePendingPortion(PendingAmount memory pendingAmount_) private view returns (uint256) {
    return (block.timestamp - pendingAmount_.createdAt) / pendingAmount_.pendingPeriod.period; // 0 1 2 3 4
  }

  /**
   * @notice Updates the claiming fee
   * @param numerator_ The fee numerator
   * @param denominator_ The fee denominator
   */
  function setFee(uint128 numerator_, uint128 denominator_) external onlyOwner {
    require(denominator_ != 0, "denominator must not equal 0");
    fee = Fee(numerator_, denominator_);
    emit FeeSet(numerator_, denominator_);
  }

  /**
   * @notice User can claim a specific pending by index
   * @param index_ The pending index to claim
   */
  function claim(uint256 index_) external whenNotPaused {
    // checks
    uint256 id = _userPendingIds[msg.sender][index_];
    PendingAmount storage pendingAmount = _userPending[msg.sender][id];

    uint256 n = getClaimablePendingPortion(pendingAmount);
    require(n != 0, "claim is still pending");

    uint256 amount;
    /**
     * @notice n is the user claimable pending portion
     * @notice Checking if user n and the user MAX n are greater than or equal
     * @notice That way we know if the user wants to claim the full amount or just part of it
     */
    if (n >= pendingAmount.pendingPeriod.repeat) {
      amount = pendingAmount.fullAmount - pendingAmount.claimedAmount;
    } else {
      uint256 percentage = (n * 1e9) / pendingAmount.pendingPeriod.repeat;
      amount = (pendingAmount.fullAmount * percentage) / 1e9 - pendingAmount.claimedAmount;
    }

    // effects
    /**
     * @notice Pending is completely done
     * @notice It will remove the pending item
     */
    if (n >= pendingAmount.pendingPeriod.repeat) {
      uint256 createdAt = pendingAmount.createdAt;
      uint256 fullAmount = pendingAmount.fullAmount;
      deletePending(index_);
      emit PendingFinished(msg.sender, createdAt, fullAmount);
    }
    /**
     * @notice Pending is partially done
     * @notice It will update the pending item
     */
    else {
      pendingAmount.claimedAmount += uint112(amount);
      emit PendingUpdated(msg.sender, pendingAmount.createdAt, pendingAmount.fullAmount);
    }

    // interactions
    uint256 feeAmount = (amount * fee.numerator) / fee.denominator;
    _token.safeTransfer(msg.sender, amount - feeAmount);

    emit Claimed(msg.sender, amount);
  }

  /**
   * @notice Owner can set staking rewards
   * @param reward_ The reward amount to set
   */
  function setReward(uint256 reward_) external onlyOwner updateReward(address(0)) {
    resetReward();

    // checks
    require(reward_ > 0, "invalid input amount");

    // effects
    rewardRate = uint152(reward_ / rewardDuration);
    _rewardUpdatedAt = uint32(block.timestamp);
    rewardFinishedAt = uint32(block.timestamp + rewardDuration);

    // interactions
    _token.safeTransferFrom(owner(), address(this), reward_);

    emit RewardSet(reward_);
  }

  /**
   * @notice Owner can increase staking rewards only if the duration isn't finished yet
   * @notice Increasing rewards doesn't alter the reward finish time
   * @param reward_ The reward amount to increase
   */
  function increaseReward(uint256 reward_) external onlyOwner updateReward(address(0)) {
    // checks
    require(reward_ > 0, "invalid input amount");
    require(block.timestamp <= rewardFinishedAt, "reward duration finished");

    // effects
    uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);
    rewardRate = uint152((remainingReward + reward_) / (rewardFinishedAt - block.timestamp));
    _rewardUpdatedAt = uint32(block.timestamp);

    // interactions
    _token.safeTransferFrom(owner(), address(this), reward_);

    emit RewardIncreased(reward_);
  }

  /**
   * @notice Owner can decrease staking rewards only if the duration isn't finished yet
   * @notice Decreasing rewards doesn't alter the reward finish time
   * @param reward_ The reward amount to decrease
   */
  function decreaseReward(uint256 reward_) external onlyOwner updateReward(address(0)) {
    // checks
    require(reward_ > 0, "invalid input amount");
    require(block.timestamp <= rewardFinishedAt, "reward duration finished");

    // effects
    uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);
    require(remainingReward > reward_, "invalid input amount");

    rewardRate = uint152((remainingReward - reward_) / (rewardFinishedAt - block.timestamp));
    _rewardUpdatedAt = uint32(block.timestamp);

    // interactions
    _token.safeTransfer(owner(), reward_);

    emit RewardDecreased(reward_);
  }

  /**
   * @notice Owner can rest all rewards and reward finish time back to 0
   */
  function resetReward() public onlyOwner updateReward(address(0)) {
    if (rewardFinishedAt <= block.timestamp) {
      rewardRate = 0;
      _rewardUpdatedAt = uint32(block.timestamp);
      rewardFinishedAt = uint32(block.timestamp);
    } else {
      // checks
      uint256 remainingReward = rewardRate * (rewardFinishedAt - block.timestamp);

      // effects
      rewardRate = 0;
      _rewardUpdatedAt = uint32(block.timestamp);
      rewardFinishedAt = uint32(block.timestamp);

      // interactions
      _token.safeTransfer(owner(), remainingReward);
    }

    emit RewardReseted();
  }

  /**
   * @notice Owner can update the reward duration
   * @notice It can only be updated if the old reward duration is already finished
   * @param rewardDuration_ The reward rewardDuration_ to use
   */
  function setRewardDuration(uint32 rewardDuration_) external onlyOwner {
    require(block.timestamp > rewardFinishedAt, "reward duration must be finalized");

    rewardDuration = rewardDuration_;

    emit RewardDurationSet(rewardDuration_);
  }

  /**
   * @notice Owner can set the pending period
   * @notice If we want a vesting period of 7 days 4 times, we can have the repeat as 4 and the period as 7 days
   * @param repeat_ The number of times to keep a withdrawal pending
   * @param period_ The period between each repeat
   */
  function setPendingPeriod(uint128 repeat_, uint128 period_) external onlyOwner {
    pendingPeriod = PendingPeriod(repeat_, period_);
    emit PendingPeriodSet(repeat_, period_);
  }

  /**
   * @notice Owner can pause the staking contract
   */
  function pause() external whenNotPaused onlyOwner {
    _pause();
  }

  /**
   * @notice Owner can resume the staking contract
   */
  function unpause() external whenPaused onlyOwner {
    _unpause();
  }

  event Staked(address indexed account, uint256 amount);
  event PendingCreated(address indexed account, uint256 createdAt, uint256 amount);
  event PendingUpdated(address indexed account, uint256 createdAt, uint256 amount);
  event PendingFinished(address indexed account, uint256 createdAt, uint256 amount);
  event PendingCanceled(address indexed account, uint256 createdAt, uint256 amount);
  event Withdrawn(address indexed account, uint256 amount);
  event Claimed(address indexed account, uint256 amount);
  event RewardSet(uint256 amount);
  event RewardIncreased(uint256 amount);
  event RewardDecreased(uint256 amount);
  event RewardReseted();
  event RewardDurationSet(uint256 duration);
  event PendingPeriodSet(uint256 repeat, uint256 period);
  event FeeSet(uint256 numerator, uint256 denominator);
  event WhitelistedSet(bool value);
  event IsWhitelistedSet(address[] users, bool[] values);
}