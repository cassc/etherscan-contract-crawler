// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMigrateable {
    function migrateAsset(address sender, uint256 tokenId) external;
}