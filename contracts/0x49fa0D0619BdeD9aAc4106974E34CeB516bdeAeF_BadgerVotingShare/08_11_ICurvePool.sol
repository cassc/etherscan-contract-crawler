// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePool {
    function balances(uint256) external pure returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 deadline) external;
}