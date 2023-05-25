// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMLFieldAgents {
    function burn(uint256[] calldata tokenIds) external;
    function ownerOf(uint256 tokenId) external view returns (address owner);
}