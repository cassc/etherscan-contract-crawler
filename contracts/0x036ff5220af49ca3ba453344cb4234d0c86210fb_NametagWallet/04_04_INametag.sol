// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INametag {
    function getByName(string memory name) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getTokenName(uint256 tokenId) external view returns (string memory);
}