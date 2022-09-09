// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.13;

interface IMetadata {    
    function getMetadata(uint256 tokenId) external view returns (uint8[] memory metadata);
    function getTraitName(uint8 traitValue) external view returns (string memory);
}