// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

interface IAaveRewardsController {

    function getUserAccruedRewards(address user, address reward) external view returns (uint256);

    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    function getAllUserRewards(
        address[] calldata assets,
        address user
    ) external view returns (
        address[] memory rewardsList,
        uint256[] memory unclaimedAmounts
    );

    function claimAllRewards(
        address[] calldata assets,
        address to
    ) external returns (
        address[] memory rewardsList,
        uint256[] memory claimedAmounts
    );

}