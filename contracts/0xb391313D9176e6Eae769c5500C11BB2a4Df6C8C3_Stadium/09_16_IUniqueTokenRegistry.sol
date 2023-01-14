// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IUniqueTokenRegistry {
    function getTokenIdByName(uint8 registry, string memory name) external view returns (uint);
    function getNameByTokenId(uint8 registry, uint tokenId) external view returns (string memory);
    function reserveTokenName(uint8 registry, string calldata name, uint tokenId) external;
    function transferOwnership(address owner) external;
}