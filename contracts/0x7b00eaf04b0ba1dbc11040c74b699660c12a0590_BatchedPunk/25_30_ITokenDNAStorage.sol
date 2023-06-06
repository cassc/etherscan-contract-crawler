// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface ITokenDNAStorage {
    function getTokenDNA(uint256 tokenId, uint256 entropy) external view returns (bytes16);
}