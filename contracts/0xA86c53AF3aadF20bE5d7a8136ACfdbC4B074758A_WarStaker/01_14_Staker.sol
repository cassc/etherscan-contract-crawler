//██████╗  █████╗ ██╗      █████╗ ██████╗ ██╗███╗   ██╗
//██╔══██╗██╔══██╗██║     ██╔══██╗██╔══██╗██║████╗  ██║
//██████╔╝███████║██║     ███████║██║  ██║██║██╔██╗ ██║
//██╔═══╝ ██╔══██║██║     ██╔══██║██║  ██║██║██║╚██╗██║
//██║     ██║  ██║███████╗██║  ██║██████╔╝██║██║ ╚████║
//╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚═╝╚═╝  ╚═══╝

pragma solidity 0.8.16;
//SPDX-License-Identifier: BUSL-1.1

import {IFarmer} from "interfaces/IFarmer.sol";
import {Owner} from "utils/Owner.sol";
import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin/security/ReentrancyGuard.sol";
import {Errors} from "utils/Errors.sol";

/**
 * @title Warlord Staking contract
 * @author Paladin
 * @notice Staking system for Warlord to distribute yield & rewards,
 *         mints an ERC20 token representing user staked amounts.
 */
contract WarStaker is ERC20, ReentrancyGuard, Pausable, Owner {
  using SafeERC20 for IERC20;

  // Constants

  /**
   * @notice 1e18 scale
   */
  uint256 private constant UNIT = 1e18;
  /**
   * @notice Max value for BPS - 100%
   */
  uint256 private constant MAX_BPS = 10_000;
  /**
   * @notice Max value possible for an uint256
   */
  uint256 private constant MAX_UINT256 = 2 ** 256 - 1;

  /**
   * @notice Duration in second of a reward distribution
   */
  uint256 private constant DISTRIBUTION_DURATION = 604_800; // 1 week
  /**
   * @notice Ratio of the total reward amount to be in the queue before moving it to distribution
   */
  uint256 private constant UPDATE_REWARD_RATIO = 8500; // 85 %

  // Structs

  /**
   * @notice UserRewardState struct
   *   lastRewardPerToken: last update reward per token value
   *   accruedRewards: total amount of rewards accrued
   */
  struct UserRewardState {
    uint256 lastRewardPerToken;
    uint256 accruedRewards;
  }

  /**
   * @notice RewardState struct
   *   rewardPerToken: current reward per token value
   *   lastUpdate: last state update timestamp
   *   distributionEndTimestamp: timestamp of the end of the current distribution
   *   ratePerSecond: current distribution rate per second
   *   currentRewardAmount: current amount of rewards in the distribution
   *   queuedRewardAmount: current amount of reward queued for the distribution
   *   userStates: users reward state for the reward token
   */
  struct RewardState {
    uint256 rewardPerToken;
    uint128 lastUpdate;
    uint128 distributionEndTimestamp;
    uint256 ratePerSecond;
    uint256 currentRewardAmount;
    uint256 queuedRewardAmount;
    // user address => user reward state
    mapping(address => UserRewardState) userStates;
  }

  /**
   * @notice UserClaimableRewards struct
   *   reward: address of the reward token
   *   claimableAmount: amount of rewards accrued by the user
   */
  struct UserClaimableRewards {
    address reward;
    uint256 claimableAmount;
  }

  /**
   * @notice UserClaimedRewards struct
   *   reward: address of the reward token
   *   amount: amount of rewards claimed by the user
   */
  struct UserClaimedRewards {
    address reward;
    uint256 amount;
  }

  // Storage

  /**
   * @notice Address of the Warlord token
   */
  address public immutable warToken;

  /**
   * @notice List of reward token distributed by this contract (past & current)
   */
  address[] public rewardTokens;
  /**
   * @notice Reward state for each reward token
   */
  mapping(address => RewardState) public rewardStates;
  /**
   * @notice Address of Farmer contract for specific reward tokens
   */
  mapping(address => address) public rewardFarmers;
  /**
   * @notice Last indexes for reward token from Farmer contracts
   */
  mapping(address => uint256) public farmerLastIndex;

  /**
   * @notice Address allowed to deposit reward tokens
   */
  mapping(address => bool) public rewardDepositors;

  // Events

  /**
   * @notice Event emitted when staking
   */
  event Staked(address indexed caller, address indexed receiver, uint256 amount);
  /**
   * @notice Event emitted when unstaking
   */
  event Unstaked(address indexed owner, address indexed receiver, uint256 amount);

  /**
   * @notice Event emitted when rewards are claimed
   */
  event ClaimedRewards(address indexed reward, address indexed user, address indexed receiver, uint256 amount);

  /**
   * @notice Event emitted when a new Claimer is set for an user
   */
  event SetUserAllowedClaimer(address indexed user, address indexed claimer);

  /**
   * @notice Event emitted when a new reward is added
   */
  event NewRewards(address indexed rewardToken, uint256 amount, uint256 endTimestamp);

  /**
   * @notice Event emitted when a new reward depositor is added
   */
  event AddedRewardDepositor(address indexed depositor);
  /**
   * @notice Event emitted when a reward depositor is removed
   */
  event RemovedRewardDepositor(address indexed depositor);

  event SetRewardFarmer(address indexed rewardToken, address indexed farmer);

  // Modifiers

  /**
   * @notice Check that the caller is allowed to deposit rewards
   */
  modifier onlyRewardDepositors() {
    if (!rewardDepositors[msg.sender]) revert Errors.CallerNotAllowed();
    _;
  }

  // Constructor

  constructor(address _warToken) ERC20("Staked Warlord token", "stkWAR") {
    if (_warToken == address(0)) revert Errors.ZeroAddress();
    warToken = _warToken;
  }

  // View functions

  /**
   * @notice Get the last update timestamp for a reward token
   * @param reward Address of the reward token
   * @return uint256 : Last update timestamp
   */
  function lastRewardUpdateTimestamp(address reward) public view returns (uint256) {
    uint256 rewardEndTimestamp = rewardStates[reward].distributionEndTimestamp;
    // If the distribution is already over, return the timestamp of the end of distribution
    // to prevent from accruing rewards that do not exist
    return block.timestamp > rewardEndTimestamp ? rewardEndTimestamp : block.timestamp;
  }

  /**
   * @notice Get the list of all reward tokens
   * @return address[] : List of reward tokens
   */
  function getRewardTokens() external view returns (address[] memory) {
    return rewardTokens;
  }

  /**
   * @notice Get the current reward state of an user for a given reward token
   * @param reward Address of the reward token
   * @param user Address of the user
   * @return UserRewardState : User reward state
   */
  function getUserRewardState(address reward, address user) external view returns (UserRewardState memory) {
    return rewardStates[reward].userStates[user];
  }

  /**
   * @notice Get the current amount of rewards accrued by an user for a given reward token
   * @param reward Address of the reward token
   * @param user Address of the user
   * @return uint256 : amount of rewards accrued
   */
  function getUserAccruedRewards(address reward, address user) external view returns (uint256) {
    return rewardStates[reward].userStates[user].accruedRewards
      + _getUserEarnedRewards(reward, user, _getNewRewardPerToken(reward));
  }

  /**
   * @notice Get all current claimable amount of rewards for all reward tokens for a given user
   * @param user Address of the user
   * @return UserClaimableRewards[] : Amounts of rewards claimable by reward token
   */
  function getUserTotalClaimableRewards(address user) external view returns (UserClaimableRewards[] memory) {
    address[] memory rewards = rewardTokens;
    uint256 rewardsLength = rewards.length;
    UserClaimableRewards[] memory rewardAmounts = new UserClaimableRewards[](rewardsLength);

    // For each listed reward
    for (uint256 i; i < rewardsLength;) {
      // Add the reward token to the list
      rewardAmounts[i].reward = rewards[i];
      // And add the calculated claimable amount of the given reward
      // Accrued rewards from previous stakes + accrued rewards from current stake
      rewardAmounts[i].claimableAmount = rewardStates[rewards[i]].userStates[user].accruedRewards
        + _getUserEarnedRewards(rewards[i], user, _getNewRewardPerToken(rewards[i]));

      unchecked {
        ++i;
      }
    }
    return rewardAmounts;
  }

  // State-changing functions

  // Can give MAX_UINT256 to stake full balance
  /**
   * @notice Stake WAR tokens
   * @param amount Amount to stake
   * @param receiver Address of the address to stake for
   * @return uint256 : scaled amount for the deposit
   */
  function stake(uint256 amount, address receiver) external nonReentrant whenNotPaused returns (uint256) {
    // If given MAX_UINT256, we want to deposit the full user balance
    if (amount == MAX_UINT256) amount = IERC20(warToken).balanceOf(msg.sender);

    if (amount == 0) revert Errors.ZeroValue();
    if (receiver == address(0)) revert Errors.ZeroAddress();

    // Pull the tokens from the user
    IERC20(warToken).safeTransferFrom(msg.sender, address(this), amount);

    // Mint the staked tokens
    // It will also update the reward states for the user who's balance gonna change
    _mint(receiver, amount);

    emit Staked(msg.sender, receiver, amount);

    return amount;
  }

  // Can give MAX_UINT256 to unstake full balance
  /**
   * @notice Unstake WAR tokens
   * @param amount Amount to unstake
   * @param receiver Address to receive the tokens
   * @return uint256 : amount unstaked
   */
  function unstake(uint256 amount, address receiver) external nonReentrant returns (uint256) {
    // If given MAX_UINT256, we want to withdraw the full user balance
    if (amount == MAX_UINT256) amount = balanceOf(msg.sender);

    if (amount == 0) revert Errors.ZeroValue();
    if (receiver == address(0)) revert Errors.ZeroAddress();

    // Burn the staked tokens
    // It will also update the reward states for the user who's balance gonna change
    _burn(msg.sender, amount);

    // And send the tokens to the given receiver
    IERC20(warToken).safeTransfer(receiver, amount);

    emit Unstaked(msg.sender, receiver, amount);

    return amount;
  }

  /**
   * @notice Claim the accrued rewards for a given reward token
   * @param reward Address of the reward token
   * @param receiver Address to receive the rewards
   * @return uint256 : Amount of rewards claimed
   */
  function claimRewards(address reward, address receiver) external nonReentrant whenNotPaused returns (uint256) {
    if (reward == address(0)) revert Errors.ZeroAddress();
    if (receiver == address(0)) revert Errors.ZeroAddress();

    return _claimRewards(reward, msg.sender, receiver);
  }

  /**
   * @notice Claim all accrued rewards for all reward tokens
   * @param receiver Address to receive the rewards
   * @return UserClaimedRewards[] : Amounts of reward claimed
   */
  function claimAllRewards(address receiver) external nonReentrant whenNotPaused returns (UserClaimedRewards[] memory) {
    if (receiver == address(0)) revert Errors.ZeroAddress();

    return _claimAllRewards(msg.sender, receiver);
  }

  /**
   * @notice Update the reward state for a given reward token
   * @param reward Address of the reward token
   */
  function updateRewardState(address reward) external nonReentrant whenNotPaused {
    if (reward == address(0)) revert Errors.ZeroAddress();
    _updateRewardState(reward);
  }

  /**
   * @notice Update the reward state for all reward tokens
   */
  function updateAllRewardStates() external nonReentrant whenNotPaused {
    address[] memory _rewards = rewardTokens;
    uint256 length = _rewards.length;

    // For all reward token in the list, update the reward state
    for (uint256 i; i < length;) {
      _updateRewardState(_rewards[i]);

      unchecked {
        ++i;
      }
    }
  }

  // Reward Managers functions

  /**
   * @notice Add rewards to the distribution queue
   * @dev Set the amount of reward in the queue & push it to distribution if reaching the ratio
   * @param rewardToken Address of the reward token
   * @param amount Amount to queue
   * @return bool : success
   */
  function queueRewards(address rewardToken, uint256 amount)
    external
    nonReentrant
    whenNotPaused
    onlyRewardDepositors
    returns (bool)
  {
    if (amount == 0) revert Errors.ZeroValue();
    if (rewardToken == address(0)) revert Errors.ZeroAddress();

    RewardState storage state = rewardStates[rewardToken];

    // If the given reward token is new (no previous distribution),
    // add it to the reward list
    if (state.lastUpdate == 0) {
      rewardTokens.push(rewardToken);
    }

    // Update the reward token state before queueing new rewards
    _updateRewardState(rewardToken);

    // Get the total queued amount (previous queued amount + new amount)
    uint256 totalQueued = amount + state.queuedRewardAmount;

    // If there is no current distribution (previous is over or new reward token):
    // Start the new distribution directly without queueing the rewards
    if (block.timestamp >= state.distributionEndTimestamp) {
      _updateRewardDistribution(rewardToken, state, totalQueued);
      state.queuedRewardAmount = 0;

      return true;
    }

    // Calculate the remaining duration for the current distribution
    // and the ratio of queued rewards compared to total rewards (queued + remaining in current distribution)
    // state.distributionEndTimestamp - block.timestamp => remaining time in the current distribution
    uint256 currentRemainingAmount = state.ratePerSecond * (state.distributionEndTimestamp - block.timestamp);
    uint256 queuedAmountRatio = (totalQueued * MAX_BPS) / (totalQueued + currentRemainingAmount);

    // If 85% or more of the total rewards are queued, move them to distribution
    if (queuedAmountRatio >= UPDATE_REWARD_RATIO) {
      _updateRewardDistribution(rewardToken, state, totalQueued);
      state.queuedRewardAmount = 0;
    } else {
      state.queuedRewardAmount = totalQueued;
    }

    return true;
  }

  /**
   * @dev Update the distribution parameters for a given reward token
   * @param rewardToken Address of the reward token
   * @param state State of the reward token
   * @param rewardAmount Total amount ot distribute
   */
  function _updateRewardDistribution(address rewardToken, RewardState storage state, uint256 rewardAmount) internal {
    // Calculate the remaining duration of the current distribution (if not already over)
    // to calculate the amount fo rewards not yet distributed, and add them to the new amount to distribute
    if (block.timestamp < state.distributionEndTimestamp) {
      uint256 remainingRewards = state.ratePerSecond * (state.distributionEndTimestamp - block.timestamp);
      rewardAmount += remainingRewards;
    }
    // Calculate the new rate per second
    // & update the storage for the new distribution state
    state.ratePerSecond = rewardAmount / DISTRIBUTION_DURATION;
    state.currentRewardAmount = rewardAmount;
    state.lastUpdate = safe128(block.timestamp);
    uint256 distributionEnd = block.timestamp + DISTRIBUTION_DURATION;
    state.distributionEndTimestamp = safe128(distributionEnd);

    emit NewRewards(rewardToken, rewardAmount, distributionEnd);
  }

  // Internal functions

  function _beforeTokenTransfer(address from, address to, uint256 /*amount*/ ) internal override {
    if (from != address(0)) {
      _updateAllUserRewardStates(from);
    }
    if (to != address(0)) {
      _updateAllUserRewardStates(to);
    }
  }

  /**
   * @dev Calculate the new rewardPerToken value for a reward token distribution
   * @param reward Address of the reward token
   * @return uint256 : new rewardPerToken value
   */
  function _getNewRewardPerToken(address reward) internal view returns (uint256) {
    RewardState storage state = rewardStates[reward];

    // If no funds are deposited, we don't want to distribute rewards
    uint256 totalStakedAmount = totalSupply();
    if (totalStakedAmount == 0) return state.rewardPerToken;

    uint256 totalAccruedAmount;
    if (rewardFarmers[reward] == address(0)) {
      // Get the last update timestamp
      uint256 lastRewardTimestamp = lastRewardUpdateTimestamp(reward);
      if (state.lastUpdate == lastRewardTimestamp) return state.rewardPerToken;
      totalAccruedAmount = (lastRewardTimestamp - state.lastUpdate) * state.ratePerSecond;
    } else {
      uint256 currentFarmerIndex = IFarmer(rewardFarmers[reward]).getCurrentIndex();
      totalAccruedAmount = currentFarmerIndex - farmerLastIndex[reward];
    }

    // Calculate the increase since the last update
    return state.rewardPerToken + ((totalAccruedAmount * UNIT) / totalStakedAmount);
  }

  /**
   * @dev Calculate the amount of rewards accrued by an user since last update for a reward token
   * @param reward Address of the reward token
   * @param user Address of the user
   * @return uint256 : Accrued rewards amount for the user
   */
  function _getUserEarnedRewards(address reward, address user, uint256 currentRewardPerToken)
    internal
    view
    returns (uint256)
  {
    UserRewardState storage userState = rewardStates[reward].userStates[user];

    // Get the user staked balance
    uint256 userStakedAmount = balanceOf(user);

    if (userStakedAmount == 0) return 0;

    // If the user has a previous deposit (scaled balance is not null), calculate the
    // earned rewards based on the increase of the rewardPerToken value
    return (userStakedAmount * (currentRewardPerToken - userState.lastRewardPerToken)) / UNIT;
  }

  /**
   * @dev Update the reward token distribution state
   * @param reward Address of the reward token
   */
  function _updateRewardState(address reward) internal {
    RewardState storage state = rewardStates[reward];

    // Update the storage with the new reward state
    state.rewardPerToken = _getNewRewardPerToken(reward);
    state.lastUpdate = safe128(lastRewardUpdateTimestamp(reward));

    if (rewardFarmers[reward] != address(0)) {
      farmerLastIndex[reward] = IFarmer(rewardFarmers[reward]).getCurrentIndex();
    }
  }

  /**
   * @dev Update the user reward state for a given reward token
   * @param reward Address of the reward token
   * @param user Address of the user
   */
  function _updateUserRewardState(address reward, address user) internal {
    // Update the reward token state before the user's state
    _updateRewardState(reward);

    UserRewardState storage userState = rewardStates[reward].userStates[user];

    // Update the storage with the new reward state
    uint256 currentRewardPerToken = rewardStates[reward].rewardPerToken;
    userState.accruedRewards += _getUserEarnedRewards(reward, user, currentRewardPerToken);
    userState.lastRewardPerToken = currentRewardPerToken;
  }

  /**
   * @dev Update the reward state of the given user for all the reward tokens
   * @param user Address of the user
   */
  function _updateAllUserRewardStates(address user) internal {
    address[] memory _rewards = rewardTokens;
    uint256 length = _rewards.length;

    // For all reward token in the list, update the user's reward state
    for (uint256 i; i < length;) {
      _updateUserRewardState(_rewards[i], user);

      unchecked {
        ++i;
      }
    }
  }

  /**
   * @dev Claims rewards of an user for a given reward token and sends them to the receiver address
   * @param reward Address of reward token
   * @param user Address of the user
   * @param receiver Address to receive the rewards
   * @return uint256 : claimed amount
   */
  function _claimRewards(address reward, address user, address receiver) internal returns (uint256) {
    // Update all user states to get all current claimable rewards
    _updateUserRewardState(reward, user);

    UserRewardState storage userState = rewardStates[reward].userStates[user];

    // Fetch the amount of rewards accrued by the user
    uint256 rewardAmount = userState.accruedRewards;

    if (rewardAmount == 0) return 0;

    // Reset user's accrued rewards
    userState.accruedRewards = 0;

    // If the user accrued rewards, send them to the given receiver
    _sendRewards(reward, receiver, rewardAmount);

    emit ClaimedRewards(reward, user, receiver, rewardAmount);

    return rewardAmount;
  }

  /**
   * @dev Claims all rewards of an user and sends them to the receiver address
   * @param user Address of the user
   * @param receiver Address to receive the rewards
   * @return UserClaimedRewards[] : list of claimed rewards
   */
  function _claimAllRewards(address user, address receiver) internal returns (UserClaimedRewards[] memory) {
    address[] memory rewards = rewardTokens;
    uint256 rewardsLength = rewards.length;

    UserClaimedRewards[] memory rewardAmounts = new UserClaimedRewards[](rewardsLength);

    // Update all user states to get all current claimable rewards
    _updateAllUserRewardStates(user);

    // For each reward token in the reward list
    for (uint256 i; i < rewardsLength;) {
      UserRewardState storage userState = rewardStates[rewards[i]].userStates[user];

      // Fetch the amount of rewards accrued by the user
      uint256 rewardAmount = userState.accruedRewards;

      // Track the claimed amount for the reward token
      rewardAmounts[i].reward = rewards[i];
      rewardAmounts[i].amount = rewardAmount;

      // If the user accrued no rewards, skip
      if (rewardAmount == 0) {
        unchecked {
          ++i;
        }
        continue;
      }

      // Reset user's accrued rewards
      userState.accruedRewards = 0;

      // For each reward token, send the accrued rewards to the given receiver
      _sendRewards(rewards[i], receiver, rewardAmount);

      emit ClaimedRewards(rewards[i], user, receiver, rewardAmounts[i].amount);

      unchecked {
        ++i;
      }
    }

    return rewardAmounts;
  }

  /**
   * @dev Sends reward token to the given receiver. Send them from the Farmer for tokens listed with a Farmer contract
   * @param token Address of the token
   * @param receiver Address to receive the rewards
   * @param amount Amount to send
   */
  function _sendRewards(address token, address receiver, uint256 amount) internal {
    if (rewardFarmers[token] == address(0)) {
      IERC20(token).safeTransfer(receiver, amount);
    } else {
      IFarmer(rewardFarmers[token]).sendTokens(receiver, amount);
    }
  }

  // Admin functions

  /**
   * @notice Pause the contract
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @notice Unpause the contract
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  /**
   * @notice Add an address to the list of allowed reward depositors
   * @param depositor Address to deposit rewards
   */
  function addRewardDepositor(address depositor) external onlyOwner {
    if (depositor == address(0)) revert Errors.ZeroAddress();
    if (rewardDepositors[depositor]) revert Errors.AlreadyListedDepositor();

    rewardDepositors[depositor] = true;

    emit AddedRewardDepositor(depositor);
  }

  /**
   * @notice Remove an address from the list of allowed reward depositors
   * @param depositor Address to deposit rewards
   */
  function removeRewardDepositor(address depositor) external onlyOwner {
    if (depositor == address(0)) revert Errors.ZeroAddress();
    if (!rewardDepositors[depositor]) revert Errors.NotListedDepositor();

    rewardDepositors[depositor] = false;

    emit RemovedRewardDepositor(depositor);
  }

  /**
   * @notice Add an Farmer contract for a reward token
   * @param rewardToken Address of the reward token
   * @param farmer Address of the Farmer contract
   */
  function setRewardFarmer(address rewardToken, address farmer) external onlyOwner {
    if (rewardToken == address(0) || farmer == address(0)) revert Errors.ZeroAddress();
    address expectedToken = IFarmer(farmer).token();
    if (rewardToken != expectedToken) revert Errors.MismatchingFarmer();

    rewardFarmers[rewardToken] = farmer;
    rewardTokens.push(rewardToken);

    emit SetRewardFarmer(rewardToken, farmer);
  }

  // Maths

  function safe128(uint256 n) internal pure returns (uint128) {
    if (n > type(uint128).max) revert Errors.NumberExceed128Bits();
    return uint128(n);
  }
}