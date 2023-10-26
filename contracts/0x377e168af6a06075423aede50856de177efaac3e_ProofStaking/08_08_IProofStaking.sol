// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

interface IProofStaking {
    struct UserInfo {
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 claimedAmount;
        uint256 claimableRewards;
        uint256 lastUnstakeTime;
        uint256 pendingUnstakeAmount;
        bool existingStaker;
    }

    /// @notice Set unstaking duration.
    /// @dev Only owner can call this function.
    function setUnstakingDuration(uint256 _duration) external;

    /// @notice Deposit accumulated ETH to staking pool again.
    /// @dev Only owner can call this function.
    function refreshPool() external;

    /// @notice Stake amount of $PROOF token.
    function stake(uint256 _amount) external;

    /// @notice Unstake amount of $PROOF token.
    /// @dev unstake amount should be less than staked amount.
    function unstake(uint256 _amount) external;

    /// @notice Restake unstaked token again.
    /// @dev All of the token that before unstake duration will be restaked.
    function restakeTokens() external;

    /// @notice Claimed unstaked token after unstaking period.
    function claimUnstakedToken() external;

    /// @notice Claim rewards.
    /// @dev Rewards are distributed as ETH.
    function claimRewards() external;

    /// @notice Get claimable rewards of the staker.
    function getClaimableRewards(
        address _staker
    ) external view returns (uint256);

    /// @notice Get all stakers address.
    function getStakers() external view returns (address[] memory);

    /// @notice Get claimable unstaked token.
    function getClaimableUnstakedToken(
        address _staker
    ) external view returns (uint256);

    /// @notice Get pending unstake amount by user.
    function getPendingUnstakeAmount(
        address _staker
    ) external view returns (uint256);

    function getTotalDepositAmount(address user) external view returns (uint256);

    function getDepositors() external view returns (address[] memory);
}