// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;

interface IETHGobblers {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}