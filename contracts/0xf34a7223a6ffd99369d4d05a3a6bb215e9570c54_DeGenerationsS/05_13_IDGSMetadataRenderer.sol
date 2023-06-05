// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IDGS {
    function shitData(uint256 tokenId) external view returns (uint8 shitType, uint32 shitNo);
}

interface IDGSMetadataRenderer {
    function render(uint256 tokenId) external view returns (string memory);
}