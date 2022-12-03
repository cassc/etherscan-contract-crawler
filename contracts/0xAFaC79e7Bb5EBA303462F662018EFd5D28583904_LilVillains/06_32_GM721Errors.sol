// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// Invalid operation. To doesn't implements IERC721Receiver(to).onERC721Received
// @param to to address.
// @param tokenId sent tokenId.
error TransferIsNotSupported(address to, uint256 tokenId);