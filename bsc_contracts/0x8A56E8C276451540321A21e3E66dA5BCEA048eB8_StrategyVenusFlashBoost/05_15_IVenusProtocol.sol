// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IVenusToken {
    function underlying() external returns (address);
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
    function balanceOfUnderlying(address owner) external returns (uint);
    function borrowBalanceStored(address account) external returns (uint);
    function comptroller() external returns (address);
}

interface IVenusUnitroller {
    function claimVenus(address holder, address[] memory vTokens) external;
    function enterMarkets(address[] memory vTokens) external;
    function exitMarket(address vToken) external;
    function getAssetsIn(address account) view external returns (address[] memory);
    function getAccountLiquidity(address account) view external returns (uint, uint, uint);
}