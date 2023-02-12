// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

/**
 * @title ICEther
 */
interface ICEther {
    function mint() external payable;
    function redeem(uint256 redeemTokens) external returns (uint256);
    function redeemUnderlying(uint redeemAmount) external returns (uint);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address dst, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function exchangeRateStored() external view returns (uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
}