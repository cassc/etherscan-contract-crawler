// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// Invalid operation. Token is already in staking.
// @param collection sent collection address.
// @param tokenId sent tokenId that belongs to collection.
error TokenAlreadyInStaking(address collection, uint256 tokenId);
// Invalid operation. Token isn't in staking.
// @param collection sent collection address.
// @param tokenId sent tokenId that belongs to collection.
error TokenIsNotInStaking(address collection, uint256 tokenId);