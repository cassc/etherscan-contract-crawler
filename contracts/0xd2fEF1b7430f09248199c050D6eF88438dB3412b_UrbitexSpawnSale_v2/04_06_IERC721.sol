// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IERC721Partial {
    function transferFrom(address from, address to, uint256 tokenId) external;
}