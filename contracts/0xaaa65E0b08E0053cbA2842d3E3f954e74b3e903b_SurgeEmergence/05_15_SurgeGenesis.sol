// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract SurgeGenesis {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}