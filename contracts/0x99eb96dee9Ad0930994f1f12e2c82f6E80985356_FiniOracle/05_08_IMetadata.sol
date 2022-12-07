// SPDX-License-Identifier: GPL-3.0

/// @title IMetdata interface

pragma solidity ^0.8.6;

interface IMetadata {
    function getMetadataForTokenId(uint256 tokenId) external view returns (uint256, uint256);
}