// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IOpenSkyIncentivesController {
    function handleAction(
        address account,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to,
        bool stake
    ) external returns (uint256);
}