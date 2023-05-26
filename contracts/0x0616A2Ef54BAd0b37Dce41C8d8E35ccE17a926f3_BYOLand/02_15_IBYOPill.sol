// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract IBYOPill {
    function ownerOf(uint256 tokenId) public virtual view returns (address owner);
}