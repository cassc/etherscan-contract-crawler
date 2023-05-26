// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC721 {
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
}