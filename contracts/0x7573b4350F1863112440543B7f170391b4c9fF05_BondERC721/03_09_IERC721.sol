// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}