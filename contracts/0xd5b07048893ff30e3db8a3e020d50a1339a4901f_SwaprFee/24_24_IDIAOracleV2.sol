// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDIAOracleV2 {
    function getValue(string memory) external view returns (uint128, uint128);
}