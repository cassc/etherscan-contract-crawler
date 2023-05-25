// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IMigrateContract {
    function migrateTokens(uint256[] calldata tokenIds, address to) external;
}