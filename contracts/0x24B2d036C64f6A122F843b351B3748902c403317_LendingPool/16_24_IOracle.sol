// SPDX-License-Identifier: No License
pragma solidity ^0.8.11;

interface IOracle {
    function getPriceUSD(address base) external view returns (int256);
}