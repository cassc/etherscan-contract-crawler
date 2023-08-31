// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.16;

interface IAavePool {

    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);

    function borrow(address asset, uint256 amount, uint256 interestRateMode, uint16 referralCode, address onBehalfOf) external;
    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256);
    function repayWithATokens(address asset,uint256 amount,uint256 interestRateMode) external returns (uint256);

    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    function getUserAccountData(address user) external view returns(
        uint256 totalCollateralBase,
        uint256 totalDebtBase,
        uint256 availableBorrowsBase,
        uint256 currentLiquidationThreshold,
        uint256 ltv,
        uint256 healthFactor
    );

}