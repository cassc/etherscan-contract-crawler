// SPDX-License-Identifier: MIT

////////////////////////////////////////////////solarde.fi//////////////////////////////////////////////
//_____/\\\\\\\\\\\_________/\\\\\_______/\\\_________________/\\\\\\\\\_______/\\\\\\\\\_____        //
// ___/\\\/////////\\\_____/\\\///\\\____\/\\\_______________/\\\\\\\\\\\\\___/\\\///////\\\___       //
//  __\//\\\______\///____/\\\/__\///\\\__\/\\\______________/\\\/////////\\\_\/\\\_____\/\\\___      //
//   ___\////\\\__________/\\\______\//\\\_\/\\\_____________\/\\\_______\/\\\_\/\\\\\\\\\\\/____     //
//    ______\////\\\______\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_\/\\\//////\\\____    //
//     _________\////\\\___\//\\\______/\\\__\/\\\_____________\/\\\/////////\\\_\/\\\____\//\\\___   //
//      __/\\\______\//\\\___\///\\\__/\\\____\/\\\_____________\/\\\_______\/\\\_\/\\\_____\//\\\__  //
//       _\///\\\\\\\\\\\/______\///\\\\\/_____\/\\\\\\\\\\\\\\\_\/\\\_______\/\\\_\/\\\______\//\\\_ //
//        ___\///////////__________\/////_______\///////////////__\///________\///__\///________\///__//
////////////////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.8.9;

interface IStakingRewards {
    struct StakingRewardsInfoResponse {
        address stakingToken;
        address rewardsToken;
        // Timestamp of when the rewards finish
        uint32 finishedAt;
        // Minimum of last updated time and reward finish time
        uint32 updatedAt;
        // Duration of rewards to be paid out (in seconds)
        uint32 duration;
        // Reward to be paid out per second
        uint256 rewardRate;
        // Sum of (reward rate * dt * 1e18 / total supply)
        uint256 rewardsPerTokenStored;
        // Total staked
        uint256 totalSupply;
        // Total amount of rewards ever added
        uint256 totalRewardsAdded;
        // Total amount of rewards ever claimed
        uint256 totalRewardsClaimed;
    }

    error StakingRewardsAmountIdsZero();
    error StakingRewardsDurationNotFinished();
    error StakingRewardsRewardRateIsZero();
    error StakingRewardsBalanceTooLow();

    /**
     * @dev Emitted when the duration is updated.
     */
    event StakingRewardsDurationUpdated(uint32 duration);

    /**
     * @dev Emitted when new rewards are added to the rewards pool.
     */
    event StakingRewardsAdded(uint256 amount);

    /**
     * @dev Emitted when a user stakes tokens.
     */
    event StakingRewardsStaked(address account, uint256 amount);

    /**
     * @dev Emitted when a user unstakes tokens.
     */
    event StakingRewardsUnstaked(address account, uint256 amount);

    /**
     * @dev Emitted when a user claims staking rewards.
     */
    event StakingRewardsClaimed(address account, uint256 amount);

    /**
     * @dev Stakes the `amount` of `stakingToken`.
     *
     * @param amount The amount to stake
     */
    function stake(uint256 amount) external;

    /**
     * @dev Unstakes the `amount` of `stakingToken`.
     *
     * @param amount The amount to stake
     */
    function unstake(uint256 amount) external;

    /**
     * @dev Claims the pending rewards.
     */
    function claimRewards() external;

    /**
     * @dev Returns the amount of tokens staked by `account`.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of tokens staked by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of rewards the `account` can claim.
     *
     * @param account Address of the account.
     *
     * @return rewards Amount of rewards the `account` can claim.
     */
    function rewardsOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens the user has already claimed.
     *
     * @param account Address of the account.
     *
     * @return rewardsClaimed Amount of rewards the `account` claimd before.
     */
    function userRewardsClaimed(
        address account
    ) external view returns (uint256 rewardsClaimed);

    /**
     * @dev Returns the last timestamp when rewards where applicable.
     * Current timestamp if the reward duration is not finished yet, `finishedAt` otherwise.
     *
     * @return timestamp The smaller of the 2 timestamps.
     */
    function lastTimeRewardApplicable() external view returns (uint256);

    /**
     * @dev Calculates the reward amount per token.
     *
     * @return rewardPerToken The calculated rewardPerToken amount.
     */
    function rewardPerToken() external view returns (uint256);

    /**
     * @dev Returns current information from the staking rewards pool.
     */
    function getInfoResponse()
        external
        view
        returns (StakingRewardsInfoResponse memory);

    /**
     * @dev Updates the duration of rewards distribution.
     * Emits an {StakingRewardsDurationUpdated} event.
     *
     * @param duration The new duration.
     */
    function setRewardsDuration(uint32 duration) external;

    /**
     * @dev Notifies the rewards pool about new tokens added.
     *
     * @param amount Amount of `rewardsToken` added to the pool.
     */
    function notifyRewardAmount(uint256 amount) external;

    /**
     * @dev Adds `rewardsToken` from `msg.sender`  to the staking rewards.
     *
     * @param amount The amount to add to the staking rewards pool.
     */
    function addRewards(uint256 amount) external;
}