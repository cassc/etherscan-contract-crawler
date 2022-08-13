// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev ABI interface to interact with the tests contract
contract ISneakerHeads {

    function ownerOf(uint256 tokenId) external view returns (address owner) {}

    function stockingLevel(uint256 tokenId) public view returns(uint64) {}
}