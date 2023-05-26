// SPDX-License-Identifier: Unlicensed 
pragma solidity ^0.8.2;

interface IStaking {
    
    // Views

    function STAKING_CAP() external view returns (uint256);

    function REWARDS_DURATION() external view returns (uint256);

    function totalStaked() external view returns (uint256);

    function stakingPeriodStart() external view returns (uint256);

    function stakingPeriodEnd() external view returns (uint256);

    function rewardsPeriodStart() external view returns (uint256);

    function rewardsPeriodEnd() external view returns (uint256);

    function rewardAmount() external view returns (uint256);
    
    function initialRewardAmount() external view returns (uint256);

    function totalRewardPaid() external view returns (uint256);

    function balanceOfStake(address account) external view returns (uint256);

    function lastTimeRewardApplicable() external view returns (uint256);

    function tokensUnlockedTimestamp() external view returns (uint256);

    function grossEarnings(address account) external view returns (uint256);

    function rewardsReceived(address account) external view returns (uint256);

    function APY(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function unstake() external;

    function claimReward() external;

    // Restricted

    function sendRewardTokens(uint256 reward) external;

    function increaseStakingPeriod(uint256 numDays) external;
}