/*

    Copyright 2020 DODO ZOO.
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.8.16;

interface ID3Vault {
    function tokens(address) external view returns(bool);
    function _ORACLE_() external view returns (address);
    function allPoolAddrMap(address) external view returns (bool);
    function poolBorrow(address token, uint256 amount) external;
    function poolRepay(address token, uint256 bTokenAmount) external;
    function poolRepayAll(address token) external;
    function poolBorrowLpFee(address token, uint256 amount) external;
    function getBorrowed(address pool, address token) external view returns (uint256);
    function getAssetInfo(address token)
        external
        view
        returns (
            address dToken,
            uint256 totalBorrows,
            uint256 totalReserves,
            uint256 reserveFactor,
            uint256 borrowIndex,
            uint256 accrualTime,
            uint256 maxDepositAmount,
            uint256 collateralWeight,
            uint256 debtWeight,
            uint256 withdrawnReserves,
            uint256 balance
        );
    function getIMMM() external view returns (uint256, uint256);
    function getUtilizationRate(address token) external view returns (uint256);
    function checkSafe(address pool) external view returns (bool);
    function checkCanBeLiquidated(address pool) external view returns (bool);
    function checkBorrowSafe(address pool) external view returns (bool);
    function allowedLiquidator(address liquidator) external view returns (bool);
    function getTotalDebtValue(address pool) external view returns (uint256);
    function getTotalAssetsValue(address pool) external view returns (uint256);
    function getTokenList() external view returns (address[] memory);
    function addD3PoolByFactory(address) external;

    function userDeposit(address user, address token) external returns(uint256);
    function userWithdraw(address to, address user, address token, uint256 dTokenAmount) external returns (uint256);

    function getExchangeRate(address token) external view returns (uint256);
}