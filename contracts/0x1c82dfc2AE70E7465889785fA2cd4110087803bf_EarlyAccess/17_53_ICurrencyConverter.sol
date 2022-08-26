// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICurrencyConverter {
    function getAmountETH(uint256 amount) external view returns (uint256);
}