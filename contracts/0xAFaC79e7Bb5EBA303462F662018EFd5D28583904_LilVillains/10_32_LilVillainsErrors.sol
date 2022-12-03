// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.9;

// Invalid operation. Collection was already revealed
error CollectionAlreadyRevealed();
// Invalid operation. Token does not exists
// @param tokenId sent tokenId.
error TokenDoesNotExists(uint256 tokenId);
// Invalid operation. Not enought supply
// @param amountOfTokensToMint sent amount of tokensToMint.
// @param currentSupply currentSupply.
// @param maxSupportedSupply maxSupportedSupply.
error SupplyIsNotEnought(uint256 amountOfTokensToMint, uint256 currentSupply, uint256 maxSupportedSupply);
// Invalid operation. Token can't be transfered because is blocked
// @param tokenId sent tokenId.
error TokenIsBlockedToTransfer(uint256 tokenId);