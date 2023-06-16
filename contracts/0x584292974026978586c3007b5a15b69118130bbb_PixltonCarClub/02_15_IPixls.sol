// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IPixls {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}