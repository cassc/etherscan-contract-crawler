// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenOwner {
    function ownerOf(uint256 tokenId) external view returns (address);
}