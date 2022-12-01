// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.9;

// See https://github.com/aave/protocol-v2/blob/master/contracts/protocol/lendingpool/LendingPool.sol
interface IAaveLendingPoolV2 {
    function getUserAccountData(address user)
    external
    view
    returns (
        uint256 totalCollateralETH,
        uint256 totalDebtETH,
        uint256 availableBorrowsETH,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}