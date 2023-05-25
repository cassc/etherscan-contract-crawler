// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

interface IBurner {
    function burn(uint256 tokenId) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function owner() external view returns (address);

    function grantRoles(address user, uint256 roles) external;
}