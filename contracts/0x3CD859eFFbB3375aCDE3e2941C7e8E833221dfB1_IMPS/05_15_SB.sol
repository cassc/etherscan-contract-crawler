// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

abstract contract Superballs {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
    function checkBalance(uint256 FH, address caller) external view virtual returns (uint256);
}