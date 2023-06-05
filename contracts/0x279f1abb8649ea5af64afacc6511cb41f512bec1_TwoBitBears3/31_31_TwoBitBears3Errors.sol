// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev The address passed in is not allowed
error InvalidAddress();

/// @dev The caller of the method is not allowed
error InvalidCaller();

/// @dev When the parent identifiers are not unique or not of the same species
error InvalidParentCombination();

/// @dev When the TwoBitBear3 tokenId does not exist
error InvalidTokenId();

/// @dev When the parent has already mated
error ParentAlreadyMated(uint256 tokenId);

/// @dev When the parent is not owned by the caller
error ParentNotOwned(uint256 tokenId);

/// @dev When the parent is not yet an adult
error ParentTooYoung(uint256 tokenId);