// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface IVenusToken {
    function mint(uint mintAmount) external returns (uint);
    function redeem(uint redeemTokens) external returns (uint);
    function borrow(uint borrowAmount) external returns (uint);
    function repayBorrow(uint repayAmount) external returns (uint);
}

interface IVenusUnitroller {
    function claimVenus(address holder) external;
    function enterMarkets(address[] calldata vTokens) external returns (uint[] memory);
}