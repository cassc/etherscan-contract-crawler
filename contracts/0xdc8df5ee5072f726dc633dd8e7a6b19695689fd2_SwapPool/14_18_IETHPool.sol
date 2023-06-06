// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

interface IETHPool {
    function unstakeAETH(uint256 shares) external;
    function getPendingUnstakesOf(address claimer) external view returns (uint256);
    function stakeAndClaimAethC() external payable;
}