/*
MathUtils

https://github.com/gysr-io/core

SPDX-License-Identifier: BSD-4-Clause
*/

pragma solidity 0.8.18;

/**
 * @title Math utilities
 *
 * @notice this library implements various logarithmic math utilies which support
 * other contracts and specifically the GYSR multiplier calculation
 *
 * @dev h/t https://github.com/abdk-consulting/abdk-libraries-solidity
 */
library MathUtils {
    /**
     * @notice calculate binary logarithm of x
     *
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function logbase2(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            int256 msb = 0;
            int256 xc = x;
            if (xc >= 0x10000000000000000) {
                xc >>= 64;
                msb += 64;
            }
            if (xc >= 0x100000000) {
                xc >>= 32;
                msb += 32;
            }
            if (xc >= 0x10000) {
                xc >>= 16;
                msb += 16;
            }
            if (xc >= 0x100) {
                xc >>= 8;
                msb += 8;
            }
            if (xc >= 0x10) {
                xc >>= 4;
                msb += 4;
            }
            if (xc >= 0x4) {
                xc >>= 2;
                msb += 2;
            }
            if (xc >= 0x2) msb += 1; // No need to shift xc anymore

            int256 result = (msb - 64) << 64;
            uint256 ux = uint256(int256(x)) << uint256(127 - msb);
            for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
                ux *= ux;
                uint256 b = ux >> 255;
                ux >>= 127 + b;
                result += bit * int256(b);
            }

            return int128(result);
        }
    }

    /**
     * @notice calculate natural logarithm of x
     * @dev magic constant comes from ln(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function ln(int128 x) internal pure returns (int128) {
        unchecked {
            require(x > 0);

            return
                int128(
                    int256(
                        (uint256(int256(logbase2(x))) *
                            0xB17217F7D1CF79ABC9E3B39803F2F6AF) >> 128
                    )
                );
        }
    }

    /**
     * @notice calculate logarithm base 10 of x
     * @dev magic constant comes from log10(2) * 2^128 -> hex
     * @param x signed 64.64-bit fixed point number, require x > 0
     * @return signed 64.64-bit fixed point number
     */
    function logbase10(int128 x) internal pure returns (int128) {
        require(x > 0);

        return
            int128(
                int256(
                    (uint256(int256(logbase2(x))) *
                        0x4d104d427de7fce20a6e420e02236748) >> 128
                )
            );
    }

    // wrapper functions to allow testing
    function testlogbase2(int128 x) public pure returns (int128) {
        return logbase2(x);
    }

    function testlogbase10(int128 x) public pure returns (int128) {
        return logbase10(x);
    }
}