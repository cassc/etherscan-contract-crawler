// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMTN {
    function activateNFT(uint256 tokenId) external;
    function getTokenActivate(uint256 tokenId) external view returns (bool);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
}