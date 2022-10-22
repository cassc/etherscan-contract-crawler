//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IDuetOracle {
    // Must 8 dec, same as chainlink decimals.
    function getPrice(address token) external view returns (uint256);
}