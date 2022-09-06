// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

library Math {
    /// @dev Compute z = x + y, where z must be non-negative and fit in a 96-bit unsigned integer
    function addInt96(uint96 x, int96 y) internal pure returns (uint96 z) {
        unchecked {
            uint256 s = x + uint256(int256(y)); // overflow is fine here
            assert(s <= type(uint96).max);
            z = uint96(s);
        }
    }

    /// @dev Compute z = x + y, where z must be non-negative and fit in a 128-bit unsigned integer
    function addInt128(uint128 x, int128 y) internal pure returns (uint128 z) {
        unchecked {
            uint256 s = x + uint256(int256(y)); // overflow is fine here
            assert(s <= type(uint128).max);
            z = uint128(s);
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x > y ? x : y;
    }

    /// @dev Subtract an amount from x until the amount reaches y or all x is subtracted (i.e. the result reches zero).
    /// Return the subtraction result and the remaining amount to subtract (if there's any)
    function subUntilZero(uint256 x, uint256 y) internal pure returns (uint256 z, uint256 r) {
        unchecked {
            if (x >= y) z = x - y;
            else r = y - x;
        }
    }

    // ----- cast -----

    function toUint128(uint256 x) internal pure returns (uint128 z) {
        assert(x <= type(uint128).max);
        z = uint128(x);
    }

    function toUint96(uint256 x) internal pure returns (uint96 z) {
        assert(x <= type(uint96).max);
        z = uint96(x);
    }

    function toInt256(uint256 x) internal pure returns (int256 z) {
        assert(x <= uint256(type(int256).max));
        z = int256(x);
    }

    function toInt96(uint96 x) internal pure returns (int96 z) {
        assert(x <= uint96(type(int96).max));
        z = int96(x);
    }

    // ----- checked arithmetic -----
    // (these functions are for using checked arithmetic in an unchecked scope)

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        z = x + y;
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y;
    }

    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        z = x - y;
    }
}