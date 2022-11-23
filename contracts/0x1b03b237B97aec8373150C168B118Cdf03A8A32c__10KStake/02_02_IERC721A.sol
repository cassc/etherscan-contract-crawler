// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721A {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);
}