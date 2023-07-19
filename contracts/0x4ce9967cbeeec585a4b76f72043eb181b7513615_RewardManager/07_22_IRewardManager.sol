// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRewardManager {
function creatorProvideBankXLiquidity() external;
function creatorProvideXSDLiquidity() external;
function userProvideBankXLiquidity(address to) external;
function userProvideXSDLiquidity(address to) external;
function userProvideCollatPoolLiquidity(address to, uint amount) external;
function LiquidityRedemption(address pool,address to) external;
}