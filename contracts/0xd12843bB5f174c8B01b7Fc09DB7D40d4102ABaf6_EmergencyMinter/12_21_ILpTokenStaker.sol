// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

interface ILpTokenStaker {
    event LpTokenStaked(address indexed account, uint256 amount);
    event LpTokenUnstaked(address indexed account, uint256 amount);
    event TokensClaimed(address indexed pool, uint256 cncAmount);
    event Shutdown();

    function stake(uint256 amount, address conicPool) external;

    function unstake(uint256 amount, address conicPool) external;

    function stakeFor(
        uint256 amount,
        address conicPool,
        address account
    ) external;

    function unstakeFor(
        uint256 amount,
        address conicPool,
        address account
    ) external;

    function unstakeFrom(uint256 amount, address account) external;

    function getUserBalanceForPool(address conicPool, address account)
        external
        view
        returns (uint256);

    function getBalanceForPool(address conicPool) external view returns (uint256);

    function updateBoost(address user) external;

    function claimCNCRewardsForPool(address pool) external;

    function claimableCnc(address pool) external view returns (uint256);

    function checkpoint(address pool) external returns (uint256);

    function shutdown() external;

    function getBoost(address user) external view returns (uint256);
}