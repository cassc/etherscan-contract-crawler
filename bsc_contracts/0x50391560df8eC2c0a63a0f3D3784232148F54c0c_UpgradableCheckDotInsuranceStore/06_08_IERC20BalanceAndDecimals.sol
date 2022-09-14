// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20BalanceAndDecimals {
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
}