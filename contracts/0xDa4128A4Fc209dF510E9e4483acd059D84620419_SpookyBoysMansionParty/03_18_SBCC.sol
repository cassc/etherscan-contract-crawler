// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

// Created By: Lorenzo
abstract contract SBCC {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}