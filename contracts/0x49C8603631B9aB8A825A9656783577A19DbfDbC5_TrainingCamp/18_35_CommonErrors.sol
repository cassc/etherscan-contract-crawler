// SPDX-License-Identifier: CC-BY-NC-ND-4.0
pragma solidity ^0.8.9;
// Invalid operation. Caller is not the token's owner.
// @param caller sent message with correct caller.
// @param collection sent collection address.
// @param tokenId sent tokenId that belongs to the collection.
error CallerIsNotOwner(address caller, address collection, uint256 tokenId);