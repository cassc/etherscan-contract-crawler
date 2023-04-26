// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReward {
    event NotifyRewardAmount(address sender, address rewardTokenAddress, uint256 amount, uint256 duration, uint256 rewardRate);
    event GetReward(address sender, address account, address recipient, uint8 rewardTokenIndex, address rewardTokenAddress, uint256 rewardPaid);
    event UnStake(address sender, address account, uint256 amount, address recipient, uint256 userBalance, uint256 totalSupply);
    event Stake(address sender, address supplier, uint256 amount, address account, uint256 userBalance, uint256 totalSupply);
    event AddRewardToken(address rewardTokenAddress, uint8 rewardTokenIndex);
    event RemoveRewardToken(address rewardTokenAddress, uint8 rewardTokenIndex);

    error DurationOutOfBounds(uint256 duration);
    error OnlyFactoryOwner();
    error ZeroAmount();
    error NotValidRewardToken(address rewardTokenAddress);
    error TooManyRewardTokens();
    error StaleToken(uint8 rewardTokenIndex);
    error TokenNotStale(uint8 rewardTokenIndex);
    error RewardStillActive(uint8 rewardTokenIndex);
    error RewardAmountBelowThreshold(uint256 amount, uint256 minimumAmount);

    struct RewardInfo {
        // Timestamp of when the rewards finish
        uint256 finishAt;
        // Minimum of last updated time and reward finish time
        uint256 updatedAt;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardPerTokenStored;
        IERC20 rewardToken;
    }

    struct EarnedInfo {
        // account
        address account;
        // earned
        uint256 earned;
        // reward token
        IERC20 rewardToken;
    }

    function rewardInfo() external view returns (RewardInfo[] memory);

    function tokenIndex(address tokenAddress) external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function earned(address account, address rewardTokenAddress) external view returns (uint256);

    function earned(address account) external view returns (EarnedInfo[] memory earnedInfo);

    /// @notice Add rewards tokens account the pot of rewards with a transferFrom.
    /// @param  rewardTokenAddress address of reward token added
    function notifyAndTransfer(address rewardTokenAddress, uint256 amount, uint256 duration) external;

    /// @notice Deposit LP tokens for reward allocation.
    /// @param amount LP token amount account deposit.
    /// @param account The receiver of `amount` deposit benefit.
    function stake(uint256 amount, address account) external;

    /// @notice Withdraw LP token stake.
    /// @param amount LP token amount account withdraw.
    /// @param  recipient Receiver of the LP tokens.
    function unstake(uint256 amount, address recipient) external;

    /// @notice Withdraw entire amount of LP token stake.
    /// @param  recipient Receiver of the LP tokens.
    function unstakeAll(address recipient) external;

    /// @notice Get reward proceeds for transaction sender account `account`.
    /// @param recipient Receiver of REWARD_TOKEN rewards.
    /// @param rewardTokenIndices indices of reward tokens to collect
    function getReward(address recipient, uint8[] calldata rewardTokenIndices) external;

    /// @notice Get reward proceeds for transaction sender account `account`.
    /// @param recipient Receiver of REWARD_TOKEN rewards.
    /// @param rewardTokenIndex index of reward token to collect
    function getReward(address recipient, uint8 rewardTokenIndex) external returns (uint256);

    /// @notice Remove stale tokens from the reward contract
    /// @param rewardTokenIndex is the index of the reward token in the
    //tokenIndex mapping
    function removeStaleToken(uint8 rewardTokenIndex) external;
}