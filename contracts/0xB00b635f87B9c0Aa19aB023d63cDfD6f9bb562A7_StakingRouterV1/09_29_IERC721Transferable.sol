// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IERC721Transferable {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}