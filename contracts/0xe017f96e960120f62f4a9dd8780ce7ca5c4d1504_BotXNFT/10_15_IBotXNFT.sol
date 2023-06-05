// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.13;

interface IBotXNFT {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);
}