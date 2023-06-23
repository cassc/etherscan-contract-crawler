// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IMetadataRenderer {
    function tokenURI(uint256 id) external view returns (string memory);
}