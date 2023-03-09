// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title Compound Math Library.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Library to perform Compound's multiplication and division in an efficient way.
library CompoundMath {
    /// CONSTANTS ///

    uint256 internal constant MAX_UINT256 = 2**256 - 1;
    uint256 public constant SCALE = 1e36;
    uint256 public constant WAD = 1e18;

    /// INTERNAL ///

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Revert if x * y > type(uint256).max
            // <=> y > 0 and x > type(uint256).max / y
            if mul(y, gt(x, div(MAX_UINT256, y))) {
                revert(0, 0)
            }

            z := div(mul(x, y), WAD)
        }
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Revert if x * SCALE > type(uint256).max or y == 0
            // <=> x > type(uint256).max / SCALE or y == 0
            if iszero(mul(y, iszero(gt(x, div(MAX_UINT256, SCALE))))) {
                revert(0, 0)
            }

            z := div(div(mul(SCALE, x), y), WAD)
        }
    }
}