// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

interface ILpTokenStaker {
    event LpTokenStaked(address indexed account, uint256 amount);
    event LpTokenUnstaked(address indexed account, uint256 amount);
    event TokensClaimed(address indexed pool, uint256 rootAmount);
    event Shutdown();

    function stake(uint256 amount, address rootPool) external;

    function unstake(uint256 amount, address rootPool) external;

    function stakeFor(
        uint256 amount,
        address rootPool,
        address account
    ) external;

    function unstakeFor(
        uint256 amount,
        address rootPool,
        address account
    ) external;

    function unstakeFrom(uint256 amount, address account) external;

    function getUserBalanceForPool(address rootPool, address account)
        external
        view
        returns (uint256);

    function getBalanceForPool(address rootPool) external view returns (uint256);

    function updateBoost(address user) external;

    function claimROOTRewardsForPool(address pool) external;

    function claimableCnc(address pool) external view returns (uint256);

    function checkpoint(address pool) external returns (uint256);

    function shutdown() external;

    function getBoost(address user) external view returns (uint256);
}