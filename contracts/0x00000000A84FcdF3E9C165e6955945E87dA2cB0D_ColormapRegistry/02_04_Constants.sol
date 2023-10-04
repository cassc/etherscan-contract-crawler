// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// -----------------------------------------------------------------------------
// Scalars
// -----------------------------------------------------------------------------

// A scalar to convert a number from [0, 255] to an 18 decimal fixed-point
// number in [0, 1] (i.e. 1e18 / 255).
uint256 constant FIXED_POINT_COLOR_VALUE_SCALAR = 3_921_568_627_450_980;

// -----------------------------------------------------------------------------
// Miscellaneous
// -----------------------------------------------------------------------------

// A look-up table to simplify the conversion from number to hexstring.
bytes32 constant HEXADECIMAL_DIGITS = "0123456789ABCDEF";