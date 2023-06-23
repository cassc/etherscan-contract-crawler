// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IERC721Ownership {
    function balanceOf(address) external view returns (uint256);
    function ownerOf(uint256) external view returns (address);
}