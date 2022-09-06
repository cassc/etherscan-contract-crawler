// SPDX-License-Identifier: MIT
pragma solidity >=0.8.14;

library Constants {
    // ACTIONS
    uint256 internal constant EXACT_INPUT = 1;
    uint256 internal constant EXACT_OUTPUT = 2;

    // SIZES
    uint256 internal constant NAME_MIN_SIZE = 3;
    uint256 internal constant NAME_MAX_SIZE = 72;

    uint256 internal constant MAX_UINT256 = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    uint128 internal constant MAX_UINT128 = type(uint128).max;

    uint256 internal constant BASE_RATIO = 1e4;
}