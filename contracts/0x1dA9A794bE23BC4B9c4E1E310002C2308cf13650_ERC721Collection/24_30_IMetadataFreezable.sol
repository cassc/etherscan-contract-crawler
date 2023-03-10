// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

interface IMetadataFreezable {
    function hasFrozenMetadata(uint256 tokenId) external view returns (bool);
}