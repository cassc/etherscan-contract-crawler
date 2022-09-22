// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRewards {
    function addRewardToken(
        address rewardsToken_,
        address distributor_,
        bool isBoosted_
    ) external;

    function claimRewards(address account_) external;

    function claimableRewards(address account_)
        external
        view
        returns (address[] memory rewardTokens_, uint256[] memory claimableAmounts_);

    function dripRewardAmount(address rewardToken_, uint256 rewardAmount_) external;

    function setRewardDistributorApproval(
        address rewardsToken_,
        address distributor_,
        bool approved_
    ) external;

    function updateReward(address account_) external;

    function lastTimeRewardApplicable(address _rewardToken) external view returns (uint256);
}