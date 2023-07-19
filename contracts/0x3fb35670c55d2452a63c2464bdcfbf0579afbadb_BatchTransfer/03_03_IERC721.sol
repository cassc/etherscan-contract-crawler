// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}