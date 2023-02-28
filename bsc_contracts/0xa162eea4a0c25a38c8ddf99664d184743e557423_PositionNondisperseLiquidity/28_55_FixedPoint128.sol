/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

/// @title FixedPoint128
/// @notice A library for handling binary fixed point numbers, see https://en.wikipedia.org/wiki/Q_(number_format)
library FixedPoint128 {
    uint256 internal constant Q128 = 0x100000000000000000000000000000000;
    uint256 internal constant BUFFER = 10 ** 24;
    uint256 internal constant Q_POW18 = 10 ** 18;
    uint256 internal constant HALF_BUFFER = 10 ** 12;
    uint32 internal constant BASIC_POINT_FEE = 10_000;
    uint8 internal constant MAX_FIND_INDEX_RANGE = 4;
}