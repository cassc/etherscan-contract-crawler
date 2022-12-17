// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns max(x - y, 0).
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns x / y rounded up (x / y + boolAsInt(x % y > 0)).
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Revert if y = 0
            if iszero(y) {
                revert(0, 0)
            }

            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}