// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

abstract contract IBYOPill {
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);
    function tokenOfOwnerByIndex(address owner, uint256 index) public virtual view returns (uint256);
}