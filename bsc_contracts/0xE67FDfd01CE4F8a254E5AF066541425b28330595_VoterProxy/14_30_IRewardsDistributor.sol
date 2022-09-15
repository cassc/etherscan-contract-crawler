// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IRewardsDistributor {
    function notifyRewardAmount(
        address stakingAddress,
        address rewardToken,
        uint256 amount
    ) external;

    function setRewardPoolOwner(address stakingAddress, address _owner)
        external;

    function setOperator(address candidate, bool status) external;

    function operator(address candidate) external returns (bool status);
}