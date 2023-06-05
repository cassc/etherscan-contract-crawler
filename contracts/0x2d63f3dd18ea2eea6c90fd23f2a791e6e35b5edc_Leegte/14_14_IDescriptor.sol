// SPDX-License-Identifier: GPL-3.0

/// @title IDescriptor interface

pragma solidity ^0.8.6;

interface IDescriptor {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}