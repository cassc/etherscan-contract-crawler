// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @dev Honey drop is frozen
error HoneyDropFrozen();

/// @dev When the burn requestor is invalid
error InvalidBurner();

/// @dev When a tokenId > 0 is supplied 
error InvalidHoneyTypeId();

/// @dev When array parameters sizes don't match
error MismatchedArraySizes();