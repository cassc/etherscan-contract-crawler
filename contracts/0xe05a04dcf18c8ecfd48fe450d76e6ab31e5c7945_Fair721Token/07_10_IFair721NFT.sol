// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IFair721NFT {
    function amountOf(uint256 tokenId) external view returns (uint256);

    function burn(uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}