//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./LPTokenWrapper.sol";
import "./interfaces/IERC20Metadata.sol";

/**
 * @title CryptoCart staking pool
 * @author Prism network
 * @dev This contract is a time-based yield farming pool with effective-staking multiplier mechanics.
 *
 * * * NOTE: A withdrawal fee of 1.5% is included which is sent to the treasury address. * * *
 */

contract CryptoCartPool is LPTokenWrapper, Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeMath for uint256;

    IERC20Metadata public immutable rewardToken;
    uint256 public immutable stakingTokenMultiplier;
    uint256 public immutable duration;
    uint256 public immutable deployedTime;

    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardRate;
    uint256 public rewardPerTokenStored;
    uint256 public totalRewardsPaid;

    struct RewardInfo {
        uint256 rewards;
        uint256 userRewardPerTokenPaid;
    }

    mapping(address => RewardInfo) public rewards;

    event RewardAdded(uint256 reward);
    event Withdrawn(address indexed user, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    // Set the staking token for the contract
    constructor(
        uint256 _duration,
        address _stakingToken,
        IERC20Metadata _rewardToken,
        address _treasury
    ) LPTokenWrapper(_stakingToken, _treasury) Ownable() {
        require(_duration != 0 && _stakingToken != address(0) && _rewardToken != IERC20Metadata(address(0)) && _treasury != address(0), "!constructor");
        stakingTokenMultiplier = 10 ** uint256(IERC20Metadata(_stakingToken).decimals());
        rewardToken = _rewardToken;
        duration = _duration;
        deployedTime = block.timestamp;
    }

    function setNewTreasury(address _treasury) external onlyOwner() {
        treasury = _treasury;
    }

    function lastTimeRewardsActive() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /* @dev Returns the current rate of rewards per token (doh) */
    function rewardPerToken() public view returns (uint256) {
        // Do not distribute rewards before startTime.
        if (block.timestamp < startTime) {
            return 0;
        }

        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }

        // Effective total supply takes into account all the multipliers bought by userbase.
        // The returrn value is time-based on last time the contract had rewards active multipliede by the reward-rate.
        // It's evened out with a division of bonus effective supply.
        return rewardPerTokenStored
            .add(
                lastTimeRewardsActive()
                .sub(lastUpdateTime)
                .mul(rewardRate)
                .mul(stakingTokenMultiplier)
                .div(totalSupply)
            );
    }

    /** @dev Returns the claimable tokens for user.*/
    function earned(address account) public view returns (uint256) {
        uint256 effectiveBalance = _balances[account].balance;
        RewardInfo memory userRewards = rewards[account];
        return effectiveBalance.mul(rewardPerToken().sub(userRewards.userRewardPerTokenPaid)).div(stakingTokenMultiplier).add(userRewards.rewards);
    }

    /** @dev Staking function which updates the user balances in the parent contract */
    function stake(uint256 amount) public override {
        require(amount > 0, "CryptoCartPool::stake: Cannot stake 0");
        updateReward(msg.sender);

        // Call the parent to adjust the balances.
        super.stake(amount);

        emit Staked(msg.sender, amount);
    }

    /** @dev Withdraw function, this pool contains a tax which is defined in the constructor */
    function withdraw(uint256 amount) public override {
        require(amount > 0, "CryptoCartPool::withdraw: Cannot withdraw 0");
        updateReward(msg.sender);

        // Adjust regular balances
        super.withdraw(amount);

        emit Withdrawn(msg.sender, amount);
    }

    // Ease-of-access function for user to remove assets from the pool.
    function exit() external {
        getReward();
        withdraw(balanceOf(msg.sender));
    }

    // Sends out the reward tokens to the user.
    function getReward() public {
        updateReward(msg.sender);
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender].rewards = 0;
            emit RewardPaid(msg.sender, reward);
            rewardToken.safeTransfer(msg.sender, reward);
            totalRewardsPaid = totalRewardsPaid.add(reward);
        }
    }

    // Called to start the pool.
    // Owner must send rewards to the contract and the balance of this token is used as the reward to account for fee on transfer tokens.
    // The reward period will be the duration of the pool.
    function notifyRewardAmount() external onlyOwner() {
        uint256 reward = rewardToken.balanceOf(address(this));
        require(reward > 0, "!reward added");
        // Update reward values
        updateRewardPerTokenStored();

        // Rewardrate must stay at a constant since it's used by end-users claiming rewards after the reward period has finished.
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(duration);
        } else {
            // Remaining time for the pool
            uint256 remainingTime = periodFinish.sub(block.timestamp);
            // And the rewards
            uint256 rewardsRemaining = remainingTime.mul(rewardRate);
            // Set the current rate
            rewardRate = reward.add(rewardsRemaining).div(duration);
        }

        // Set the last updated
        lastUpdateTime = block.timestamp;
        startTime = block.timestamp;
        // Add the period to be equal to duration set.s
        periodFinish = block.timestamp.add(duration);
        emit RewardAdded(reward);
    }

    // Ejects any remaining tokens from the pool.
    // Callable only after the pool has started and the pools reward distribution period has finished.
    function eject() external onlyOwner() {
        require(block.timestamp >= periodFinish + 12 hours, "CryptoCartPool::eject: Cannot eject before period finishes or pool has started");
        uint256 currBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(msg.sender, currBalance);
    }

    // Forcefully retire a pool
    // Only sets the period finish to 0
    // This will prevent more rewards from being disbursed
    function kill() external onlyOwner() {
        periodFinish = block.timestamp;
    }

    // Callable only after the pool has started and the pools reward distribution period has finished.
    function emergencyWithdraw() external {
        require(block.timestamp >= periodFinish + 12 hours, "CryptoCartPool::emergencyWithdraw: Cannot emergency withdraw before period finishes or pool has started");
        uint256 fullWithdrawal = balanceOf(msg.sender);
        require(fullWithdrawal > 0, "CryptoCartPool::emergencyWithdraw: Cannot withdraw 0");
        super.withdraw(fullWithdrawal);
        emit Withdrawn(msg.sender, fullWithdrawal);
    }

    function updateRewardPerTokenStored() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardsActive();
    }

    function updateReward(address account) internal {
        updateRewardPerTokenStored();
        rewards[account].rewards = earned(account);
        rewards[account].userRewardPerTokenPaid = rewardPerTokenStored;
    }
}