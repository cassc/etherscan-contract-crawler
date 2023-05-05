// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface ICompoundToken {
    function underlying() external returns (address);
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceStored(address account) external returns (uint);
    function getAccountSnapshot(address account) external view returns (uint, uint, uint, uint);
    function comptroller() external returns (address);
}

interface ICompoundUnitroller {
    function enterMarkets(address[] memory cTokens) external;
    function exitMarket(address cToken) external;
    function getAssetsIn(address account) view external returns (address[] memory);
    function getAccountLiquidity(address account) view external returns (uint, uint, uint);
}