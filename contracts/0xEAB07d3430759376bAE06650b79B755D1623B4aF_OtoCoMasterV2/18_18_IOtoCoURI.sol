// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOtoCoURI {
    function tokenExternalURI(uint256 tokenId, uint256 lastMigrated) external view returns (string memory);
}