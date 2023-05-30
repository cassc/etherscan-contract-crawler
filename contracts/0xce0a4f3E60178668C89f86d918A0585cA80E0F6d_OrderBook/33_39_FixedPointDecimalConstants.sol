// SPDX-License-Identifier: CAL
pragma solidity ^0.8.18;

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FIXED_POINT_DECIMALS = 18;

/// @dev Value of "one" for fixed point math.
uint256 constant FIXED_POINT_ONE = 1e18;

/// @dev Calculations MUST round up.
uint256 constant FLAG_ROUND_UP = 1;

/// @dev Calculations MUST saturate NOT overflow.
uint256 constant FLAG_SATURATE = 1 << 1;

/// @dev Flags MUST NOT exceed this value.
uint256 constant FLAG_MAX_INT = FLAG_SATURATE | FLAG_ROUND_UP;

/// @dev Can't represent this many OOMs of decimals in `uint256`.
uint256 constant OVERFLOW_RESCALE_OOMS = 78;