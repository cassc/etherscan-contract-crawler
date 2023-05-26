// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev When total adoption quantity has been reached
error AdoptionLimitReached();

/// @dev When cub aging has already started
error AgingAlreadyStarted();

/// @dev When the parent bear is not owned by the caller
error BearNotOwned(uint256 tokenId);

/// @dev When the cub is not owned by the caller
error CubNotOwned(uint256 tokenId);

/// @dev When adoption quantity is too high or too low
error InvalidAdoptionQuantity();

/// @dev When the parent identifiers are not unique or not of the same species
error InvalidParentCombination();

/// @dev When the price for adoption is not correct
error InvalidPriceSent();

/// @dev When the maximum number of cubs has been met
error NoMoreCubs();

/// @dev When the cub tokenId does not exist
error NonexistentCub();

/// @dev When minting block hasn't yet been reached
error NotOpenForMinting();

/// @dev When Reveal is false
error NotYetRevealed();