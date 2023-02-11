/**
 *Submitted for verification at Etherscan.io on 2023-02-10
*/

// SPDX-License-Identifier: VPL - VIRAL PUBLIC LICENSE
pragma solidity ^0.8.13;

/// @notice Library to encode strings in Base64.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
/// @author Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos - <[email protected]>.
library Base64 {
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    function encode(bytes memory data, bool fileSafe, bool noPadding)
        internal
        pure
        returns (string memory result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                // Multiply by 4/3 rounded up.
                // The `shl(2, ...)` is equivalent to multiplying by 4.
                let encodedLength := shl(2, div(add(dataLength, 2), 3))

                // Set `result` to point to the start of the free memory.
                result := mload(0x40)

                // Store the table into the scratch space.
                // Offsetted by -1 byte so that the `mload` will load the character.
                // We will rewrite the free memory pointer at `0x40` later with
                // the allocated size.
                // The magic constant 0x0230 will translate "-_" + "+/".
                mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
                mstore(0x3f, sub("ghijklmnopqrstuvwxyz0123456789-_", mul(iszero(fileSafe), 0x0230)))

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)
                let end := add(ptr, encodedLength)

                // Run over the input, 3 bytes at a time.
                for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(ptr, mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr(6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(input, 0x3F)))

                    ptr := add(ptr, 4) // Advance 4 bytes.

                    if iszero(lt(ptr, end)) { break }
                }

                let r := mod(dataLength, 3)

                switch noPadding
                case 0 {
                    // Offset `ptr` and pad with '='. We can simply write over the end.
                    mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                    mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
                    // Write the length of the string.
                    mstore(result, encodedLength)
                }
                default {
                    // Write the length of the string.
                    mstore(result, sub(encodedLength, add(iszero(iszero(r)), eq(r, 1))))
                }

                // Allocate the memory for the string.
                // Add 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(end, 31), not(31)))
            }
        }
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, false, false)`.
    function encode(bytes memory data) internal pure returns (string memory result) {
        result = encode(data, false, false);
    }

    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// Equivalent to `encode(data, fileSafe, false)`.
    function encode(bytes memory data, bool fileSafe)
        internal
        pure
        returns (string memory result)
    {
        result = encode(data, fileSafe, false);
    }

    /// @dev Encodes base64 encoded `data`.
    ///
    /// Supports:
    /// - RFC 4648 (both standard and file-safe mode).
    /// - RFC 3501 (63: ',').
    ///
    /// Does not support:
    /// - Line breaks.
    ///
    /// Note: For performance reasons,
    /// this function will NOT revert on invalid `data` inputs.
    /// Outputs for invalid inputs will simply be undefined behaviour.
    /// It is the user's responsibility to ensure that the `data`
    /// is a valid base64 encoded string.
    function decode(string memory data) internal pure returns (bytes memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            let dataLength := mload(data)

            if dataLength {
                let end := add(data, dataLength)
                let decodedLength := mul(shr(2, dataLength), 3)

                switch and(dataLength, 3)
                case 0 {
                    // If padded.
                    // forgefmt: disable-next-item
                    decodedLength := sub(
                        decodedLength,
                        add(eq(and(mload(end), 0xFF), 0x3d), eq(and(mload(end), 0xFFFF), 0x3d3d))
                    )
                }
                default {
                    // If non-padded.
                    decodedLength := add(decodedLength, sub(and(dataLength, 3), 1))
                }

                result := mload(0x40)

                // Write the length of the string.
                mstore(result, decodedLength)

                // Skip the first slot, which stores the length.
                let ptr := add(result, 0x20)

                // Load the table into the scratch space.
                // Constants are optimized for smaller bytecode with zero gas overhead.
                // `m` also doubles as the mask of the upper 6 bits.
                let m := 0xfc000000fc00686c7074787c8084888c9094989ca0a4a8acb0b4b8bcc0c4c8cc
                mstore(0x5b, m)
                mstore(0x3b, 0x04080c1014181c2024282c3034383c4044484c5054585c6064)
                mstore(0x1a, 0xf8fcf800fcd0d4d8dce0e4e8ecf0f4)

                for {} 1 {} {
                    // Read 4 bytes.
                    data := add(data, 4)
                    let input := mload(data)

                    // Write 3 bytes.
                    // forgefmt: disable-next-item
                    mstore(ptr, or(
                        and(m, mload(byte(28, input))),
                        shr(6, or(
                            and(m, mload(byte(29, input))),
                            shr(6, or(
                                and(m, mload(byte(30, input))),
                                shr(6, mload(byte(31, input)))
                            ))
                        ))
                    ))

                    ptr := add(ptr, 3)

                    if iszero(lt(data, end)) { break }
                }

                // Allocate the memory for the string.
                // Add 32 + 31 and mask with `not(31)` to round the
                // free memory pointer up the next multiple of 32.
                mstore(0x40, and(add(add(result, decodedLength), 63), not(31)))

                // Restore the zero slot.
                mstore(0x60, 0)
            }
        }
    }
}

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

/**
 * @notice Solidity library offering basic trigonometry functions where inputs and outputs are
 * integers. Inputs are specified in radians scaled by 1e18, and similarly outputs are scaled by 1e18.
 *
 * This implementation is based off the Solidity trigonometry library written by Lefteris Karapetsas
 * which can be found here: https://github.com/Sikorkaio/sikorka/blob/e75c91925c914beaedf4841c0336a806f2b5f66d/contracts/trigonometry.sol
 *
 * Compared to Lefteris' implementation, this version makes the following changes:
 *   - Uses a 32 bits instead of 16 bits for improved accuracy
 *   - Updated for Solidity 0.8.x
 *   - Various gas optimizations
 *   - Change inputs/outputs to standard trig format (scaled by 1e18) instead of requiring the
 *     integer format used by the algorithm
 *
 * Lefertis' implementation is based off Dave Dribin's trigint C library
 *     http://www.dribin.org/dave/trigint/
 *
 * Which in turn is based from a now deleted article which can be found in the Wayback Machine:
 *     http://web.archive.org/web/20120301144605/http://www.dattalo.com/technical/software/pic/picsine.html
 */
library Trigonometry {
  // Table index into the trigonometric table
  uint256 constant INDEX_WIDTH        = 8;
  // Interpolation between successive entries in the table
  uint256 constant INTERP_WIDTH       = 16;
  uint256 constant INDEX_OFFSET       = 28 - INDEX_WIDTH;
  uint256 constant INTERP_OFFSET      = INDEX_OFFSET - INTERP_WIDTH;
  uint32  constant ANGLES_IN_CYCLE    = 1073741824;
  uint32  constant QUADRANT_HIGH_MASK = 536870912;
  uint32  constant QUADRANT_LOW_MASK  = 268435456;
  uint256 constant SINE_TABLE_SIZE    = 256;

  // Pi as an 18 decimal value, which is plenty of accuracy: "For JPL's highest accuracy calculations, which are for
  // interplanetary navigation, we use 3.141592653589793: https://www.jpl.nasa.gov/edu/news/2016/3/16/how-many-decimals-of-pi-do-we-really-need/
  uint256 constant PI          = 3141592653589793238;
  uint256 constant TWO_PI      = 2 * PI;
  uint256 constant PI_OVER_TWO = PI / 2;

  // The constant sine lookup table was generated by generate_trigonometry.py. We must use a constant
  // bytes array because constant arrays are not supported in Solidity. Each entry in the lookup
  // table is 4 bytes. Since we're using 32-bit parameters for the lookup table, we get a table size
  // of 2^(32/4) + 1 = 257, where the first and last entries are equivalent (hence the table size of
  // 256 defined above)
  uint8   constant entry_bytes = 4; // each entry in the lookup table is 4 bytes
  uint256 constant entry_mask  = ((1 << 8*entry_bytes) - 1); // mask used to cast bytes32 -> lookup table entry
  bytes   constant sin_table   = hex"00_00_00_00_00_c9_0f_88_01_92_1d_20_02_5b_26_d7_03_24_2a_bf_03_ed_26_e6_04_b6_19_5d_05_7f_00_35_06_47_d9_7c_07_10_a3_45_07_d9_5b_9e_08_a2_00_9a_09_6a_90_49_0a_33_08_bc_0a_fb_68_05_0b_c3_ac_35_0c_8b_d3_5e_0d_53_db_92_0e_1b_c2_e4_0e_e3_87_66_0f_ab_27_2b_10_72_a0_48_11_39_f0_cf_12_01_16_d5_12_c8_10_6e_13_8e_db_b1_14_55_76_b1_15_1b_df_85_15_e2_14_44_16_a8_13_05_17_6d_d9_de_18_33_66_e8_18_f8_b8_3c_19_bd_cb_f3_1a_82_a0_25_1b_47_32_ef_1c_0b_82_6a_1c_cf_8c_b3_1d_93_4f_e5_1e_56_ca_1e_1f_19_f9_7b_1f_dc_dc_1b_20_9f_70_1c_21_61_b3_9f_22_23_a4_c5_22_e5_41_af_23_a6_88_7e_24_67_77_57_25_28_0c_5d_25_e8_45_b6_26_a8_21_85_27_67_9d_f4_28_26_b9_28_28_e5_71_4a_29_a3_c4_85_2a_61_b1_01_2b_1f_34_eb_2b_dc_4e_6f_2c_98_fb_ba_2d_55_3a_fb_2e_11_0a_62_2e_cc_68_1e_2f_87_52_62_30_41_c7_60_30_fb_c5_4d_31_b5_4a_5d_32_6e_54_c7_33_26_e2_c2_33_de_f2_87_34_96_82_4f_35_4d_90_56_36_04_1a_d9_36_ba_20_13_37_6f_9e_46_38_24_93_b0_38_d8_fe_93_39_8c_dd_32_3a_40_2d_d1_3a_f2_ee_b7_3b_a5_1e_29_3c_56_ba_70_3d_07_c1_d5_3d_b8_32_a5_3e_68_0b_2c_3f_17_49_b7_3f_c5_ec_97_40_73_f2_1d_41_21_58_9a_41_ce_1e_64_42_7a_41_d0_43_25_c1_35_43_d0_9a_ec_44_7a_cd_50_45_24_56_bc_45_cd_35_8f_46_75_68_27_47_1c_ec_e6_47_c3_c2_2e_48_69_e6_64_49_0f_57_ee_49_b4_15_33_4a_58_1c_9d_4a_fb_6c_97_4b_9e_03_8f_4c_3f_df_f3_4c_e1_00_34_4d_81_62_c3_4e_21_06_17_4e_bf_e8_a4_4f_5e_08_e2_4f_fb_65_4c_50_97_fc_5e_51_33_cc_94_51_ce_d4_6e_52_69_12_6e_53_02_85_17_53_9b_2a_ef_54_33_02_7d_54_ca_0a_4a_55_60_40_e2_55_f5_a4_d2_56_8a_34_a9_57_1d_ee_f9_57_b0_d2_55_58_42_dd_54_58_d4_0e_8c_59_64_64_97_59_f3_de_12_5a_82_79_99_5b_10_35_ce_5b_9d_11_53_5c_29_0a_cc_5c_b4_20_df_5d_3e_52_36_5d_c7_9d_7b_5e_50_01_5d_5e_d7_7c_89_5f_5e_0d_b2_5f_e3_b3_8d_60_68_6c_ce_60_ec_38_2f_61_6f_14_6b_61_f1_00_3e_62_71_fa_68_62_f2_01_ac_63_71_14_cc_63_ef_32_8f_64_6c_59_bf_64_e8_89_25_65_63_bf_91_65_dd_fb_d2_66_57_3c_bb_66_cf_81_1f_67_46_c7_d7_67_bd_0f_bc_68_32_57_aa_68_a6_9e_80_69_19_e3_1f_69_8c_24_6b_69_fd_61_4a_6a_6d_98_a3_6a_dc_c9_64_6b_4a_f2_78_6b_b8_12_d0_6c_24_29_5f_6c_8f_35_1b_6c_f9_34_fb_6d_62_27_f9_6d_ca_0d_14_6e_30_e3_49_6e_96_a9_9c_6e_fb_5f_11_6f_5f_02_b1_6f_c1_93_84_70_23_10_99_70_83_78_fe_70_e2_cb_c5_71_41_08_04_71_9e_2c_d1_71_fa_39_48_72_55_2c_84_72_af_05_a6_73_07_c3_cf_73_5f_66_25_73_b5_eb_d0_74_0b_53_fa_74_5f_9d_d0_74_b2_c8_83_75_04_d3_44_75_55_bd_4b_75_a5_85_ce_75_f4_2c_0a_76_41_af_3c_76_8e_0e_a5_76_d9_49_88_77_23_5f_2c_77_6c_4e_da_77_b4_17_df_77_fa_b9_88_78_40_33_28_78_84_84_13_78_c7_ab_a1_79_09_a9_2c_79_4a_7c_11_79_8a_23_b0_79_c8_9f_6d_7a_05_ee_ac_7a_42_10_d8_7a_7d_05_5a_7a_b6_cb_a3_7a_ef_63_23_7b_26_cb_4e_7b_5d_03_9d_7b_92_0b_88_7b_c5_e2_8f_7b_f8_88_2f_7c_29_fb_ed_7c_5a_3d_4f_7c_89_4b_dd_7c_b7_27_23_7c_e3_ce_b1_7d_0f_42_17_7d_39_80_eb_7d_62_8a_c5_7d_8a_5f_3f_7d_b0_fd_f7_7d_d6_66_8e_7d_fa_98_a7_7e_1d_93_e9_7e_3f_57_fe_7e_5f_e4_92_7e_7f_39_56_7e_9d_55_fb_7e_ba_3a_38_7e_d5_e5_c5_7e_f0_58_5f_7f_09_91_c3_7f_21_91_b3_7f_38_57_f5_7f_4d_e4_50_7f_62_36_8e_7f_75_4e_7f_7f_87_2b_f2_7f_97_ce_bc_7f_a7_36_b3_7f_b5_63_b2_7f_c2_55_95_7f_ce_0c_3d_7f_d8_87_8d_7f_e1_c7_6a_7f_e9_cb_bf_7f_f0_94_77_7f_f6_21_81_7f_fa_72_d0_7f_fd_88_59_7f_ff_62_15_7f_ff_ff_ff";

  /**
   * @notice Return the sine of a value, specified in radians scaled by 1e18
   * @dev This algorithm for converting sine only uses integer values, and it works by dividing the
   * circle into 30 bit angles, i.e. there are 1,073,741,824 (2^30) angle units, instead of the
   * standard 360 degrees (2pi radians). From there, we get an output in range -2,147,483,647 to
   * 2,147,483,647, (which is the max value of an int32) which is then converted back to the standard
   * range of -1 to 1, again scaled by 1e18
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function sin(uint256 _angle) internal pure returns (int256) {
    unchecked {
      // Convert angle from from arbitrary radian value (range of 0 to 2pi) to the algorithm's range
      // of 0 to 1,073,741,824
      _angle = ANGLES_IN_CYCLE * (_angle % TWO_PI) / TWO_PI;

      // Apply a mask on an integer to extract a certain number of bits, where angle is the integer
      // whose bits we want to get, the width is the width of the bits (in bits) we want to extract,
      // and the offset is the offset of the bits (in bits) we want to extract. The result is an
      // integer containing _width bits of _value starting at the offset bit
      uint256 interp = (_angle >> INTERP_OFFSET) & ((1 << INTERP_WIDTH) - 1);
      uint256 index  = (_angle >> INDEX_OFFSET)  & ((1 << INDEX_WIDTH)  - 1);

      // The lookup table only contains data for one quadrant (since sin is symmetric around both
      // axes), so here we figure out which quadrant we're in, then we lookup the values in the
      // table then modify values accordingly
      bool is_odd_quadrant      = (_angle & QUADRANT_LOW_MASK)  == 0;
      bool is_negative_quadrant = (_angle & QUADRANT_HIGH_MASK) != 0;

      if (!is_odd_quadrant) {
        index = SINE_TABLE_SIZE - 1 - index;
      }

      bytes memory table = sin_table;
      // We are looking for two consecutive indices in our lookup table
      // Since EVM is left aligned, to read n bytes of data from idx i, we must read from `i * data_len` + `n`
      // therefore, to read two entries of size entry_bytes `index * entry_bytes` + `entry_bytes * 2`
      uint256 offset1_2 = (index + 2) * entry_bytes;

      // This following snippet will function for any entry_bytes <= 15
      uint256 x1_2; assembly {
        // mload will grab one word worth of bytes (32), as that is the minimum size in EVM
        x1_2 := mload(add(table, offset1_2))
      }

      // We now read the last two numbers of size entry_bytes from x1_2
      // in example: entry_bytes = 4; x1_2 = 0x00...12345678abcdefgh
      // therefore: entry_mask = 0xFFFFFFFF

      // 0x00...12345678abcdefgh >> 8*4 = 0x00...12345678
      // 0x00...12345678 & 0xFFFFFFFF = 0x12345678
      uint256 x1 = x1_2 >> 8*entry_bytes & entry_mask;
      // 0x00...12345678abcdefgh & 0xFFFFFFFF = 0xabcdefgh
      uint256 x2 = x1_2 & entry_mask;

      // Approximate angle by interpolating in the table, accounting for the quadrant
      uint256 approximation = ((x2 - x1) * interp) >> INTERP_WIDTH;
      int256 sine = is_odd_quadrant ? int256(x1) + int256(approximation) : int256(x2) - int256(approximation);
      if (is_negative_quadrant) {
        sine *= -1;
      }

      // Bring result from the range of -2,147,483,647 through 2,147,483,647 to -1e18 through 1e18.
      // This can never overflow because sine is bounded by the above values
      return sine * 1e18 / 2_147_483_647;
    }
  }

  /**
   * @notice Return the cosine of a value, specified in radians scaled by 1e18
   * @dev This is identical to the sin() method, and just computes the value by delegating to the
   * sin() method using the identity cos(x) = sin(x + pi/2)
   * @dev Overflow when `angle + PI_OVER_TWO > type(uint256).max` is ok, results are still accurate
   * @param _angle Angle to convert
   * @return Result scaled by 1e18
   */
  function cos(uint256 _angle) internal pure returns (int256) {
    unchecked {
      return sin(_angle + PI_OVER_TWO);
    }
  }
}

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        /// @solidity memory-safe-assembly
        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

enum PruneDegrees {NONE, LOW, MEDIUM, HIGH}

enum HealthStatus {OK, DRY, DEAD}

struct BonsaiProfile {
    uint256 modifiedSteps;

    uint64 adjustedStartTime;
    uint64 ratio;
    uint32 seed;
    uint8 trunkSVGNumber;

    uint64 lastWatered;
}

struct WateringStatus {
    uint64 lastWatered; 
    HealthStatus healthStatus;
    string status;
}

struct Vars {
    uint256 layer;
    uint256 strokeWidth;
    bytes32[12] gradients;
}

struct RawAttributes {
    bytes32 backgroundColor;
    bytes32 blossomColor;
    bytes32 wateringStatus;

    uint32 seed;
    uint64 ratio;
    uint64 adjustedStartTime;
    uint64 lastWatered;
    uint8 trunkSVGNumber;
    HealthStatus healthStatus;

    uint256[] modifiedSteps;
}

interface IBonsaiRenderer {
    function numTrunks() external view returns(uint256);
    function renderForHumans(uint256 tokenId) external view returns(string memory);
    function renderForRobots(uint256 tokenId) external view returns(RawAttributes memory);
}

interface IBonsaiState {
    function getBonsaiProfile(uint256 tokenId) external view returns(BonsaiProfile memory);
    function initializeBonsai(uint256 tokenId, bool mayBeBot) external;
    function water(uint256 tokenId) external returns(WateringStatus memory);
    function wateringStatus(uint256 tokenId) external view returns(WateringStatus memory);
    function wateringStatusForRender(uint64 lastWatered, uint64 adjustedStartTime, bool watering) external view returns(WateringStatus memory ws);
    function prune(uint256 tokenId, PruneDegrees degree) external;
}

library StringsExtended {
    bytes17 private constant _SYMBOLS = "0123456789abcdef.";

    function toStringDecimal(uint256 value, uint256 decimals) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            length = (length > decimals+1) ? length : decimals+2; // '0.'
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            uint256 idx;
            while (true) {
                --ptr;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                //if (value == 0) break;
                ++idx;
                if (idx == decimals) break;
            }
            --ptr;
            assembly {
                mstore8(ptr, byte(16, _SYMBOLS))
            }
            while (true) {
                --ptr;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }
}

library HelpersLib {

    function _getPointInRange(uint64 center, uint64 intervalWidth, uint256 seed) internal pure returns(uint64 ratio) {
        // unchecked assuming caller picks center and intervalWidth that would be safe and sensible
        uint256 jump = seed % uint256(intervalWidth);
        unchecked{
        if (seed % 2 == 0) {
            ratio = center + uint64(jump); 
        } else {
            ratio = center - uint64(jump); 
        }
        }//uc
    }

    function _toUint8Arr(uint256 encoded) internal pure returns(uint256[] memory) {
        uint256 mask = uint256(type(uint8).max); 
        uint256[] memory ret = new uint256[](32);
        uint256 shift;
        unchecked{
        for (uint256 i; i < 32; ++i) {
            shift = i*8; 
            ret[i] = (encoded & (mask << shift)) >> shift;
        }
        }//uc
        return ret;
    }

    function _buildStringArray(uint256[] memory nums) internal pure returns(string memory) {
        bytes memory tmp;
        uint256 numsLength = nums.length;
        unchecked{
        for (uint256 i; i < numsLength; ++i) {
            tmp = abi.encodePacked(tmp, Strings.toString(nums[i]), ",");
        }
        }//uc
        return string(abi.encodePacked(
                  "[",
                  tmp,
                  "]" 
        ));
    }

    function _push(uint256[] memory arrayStack, uint256 value) internal pure {
        unchecked{ // protected by _maxCacheSize initializing the cache
        ++arrayStack[0];
        }//uc
        arrayStack[arrayStack[0]] = value;
    }

    function _pop(uint256[] memory arrayStack) internal pure returns(uint256 value) {
        if (arrayStack[0] == 0) return type(uint256).max; // semantic overloading 
        value = arrayStack[arrayStack[0]]; 
        unchecked{
        --arrayStack[0];
        }// protected by first line
    }

    function _getUint8(uint256 pad, uint256 idx) internal pure returns(uint256) {
        unchecked{
        return pad >> (idx*8) & type(uint8).max; 
        }//uc assuming all static calls are by dev
    }

    function _steppedHash(uint256 seed, uint256 step) internal pure returns(uint256 result) {
        assembly {
           let m := add(mload(0x40), 0x40) // 0x40 two words
            // Update the free memory pointer to allocate.
            mstore(0x40, m)
            
            mstore(m, seed)
            mstore(add(m, 0x20), step)

            result := keccak256(m, 0x40)
        } 
    }
}

contract BonsaiRenderer is IBonsaiRenderer {

    address private _bonsaiNFT;
    IBonsaiState private _bonsaiState;

    address public OWNER;

    uint256 constant private PI = 3141592653589793238;
    uint64 constant private PHI = 1618033988749894848;
    uint256 constant private ONE = 10**18;
    uint256 constant private MAX_BRANCHES = 7;

    mapping(uint256 => address) private _trunkTypePtrs;
    uint256 private _numTrunks;

    mapping(uint256 => address) private _svgXMLPtrs;

    constructor(address owner_, address bonsaiState_) {
        OWNER = owner_;

        _bonsaiState = IBonsaiState(bonsaiState_);

    }

    function _onlyOwner() private view {
        require(msg.sender == OWNER, "not owner.");
    }

    function _onlyBonsaiNFT() private view {
        require(msg.sender == _bonsaiNFT, "not BonsaiNFT.");
    }

    function setBonsaiNFT(address bonsaiNFT_) external {
        _onlyOwner();
        require(_bonsaiNFT == address(0), "can only be set once.");
        _bonsaiNFT = bonsaiNFT_;
    }

    function setTrunkSVGs(string[] calldata trunkSVGs) external {
        _onlyOwner();
        require(_numTrunks == 0, "trunkSVG already exists.");
        uint256 trunkSVGsLength = trunkSVGs.length;
        for (uint256 i; i < trunkSVGsLength; ++i) {
            _trunkTypePtrs[i] = SSTORE2.write(bytes(trunkSVGs[i]));
        }
        _numTrunks = trunkSVGsLength;
    }

    function setSVGXML(string[] calldata svgXML) external {
        _onlyOwner();
        unchecked{
        for (uint256 i; i < svgXML.length; ++i) {
            if (_svgXMLPtrs[i] == address(0)) { // owner can only set each data once
                _svgXMLPtrs[i] = SSTORE2.write(bytes(svgXML[i]));
            }
        }
        }//uc
    }

    function numTrunks() external view returns(uint256) {
        return _numTrunks;
    }

    function _maxCacheSize(uint256 maxValues, uint256 maxBranches) private pure returns(uint256) {
        unchecked{ // assuming safe values
        // naiive and a bit ignorant, but safe
        uint256 idx;
        uint256 finalLevel;
        uint256 sum;
        while (sum < maxValues) {
            finalLevel = maxBranches**idx;
            sum += finalLevel; 
            ++idx;
        }
        return finalLevel;
        }//uc
    }

    function renderForRobots(uint256 tokenId) external view returns(RawAttributes memory ra) {
        _onlyBonsaiNFT();
        BonsaiProfile memory bp = _bonsaiState.getBonsaiProfile(tokenId);
        WateringStatus memory ws = _bonsaiState.wateringStatusForRender({lastWatered: bp.lastWatered, adjustedStartTime: bp.adjustedStartTime, watering: false});

        return RawAttributes({
            seed: bp.seed,
            ratio: bp.ratio,
            adjustedStartTime: bp.adjustedStartTime,
            backgroundColor: _getBackgroundColor(bp.seed),
            trunkSVGNumber: bp.trunkSVGNumber,
            blossomColor: (ws.healthStatus == HealthStatus.OK) ? _getBlossomColor(bp.seed) : bytes32("none"), // len < 32
            healthStatus: ws.healthStatus,
            lastWatered: ws.lastWatered,
            wateringStatus: bytes32(bytes(ws.status)), // len < 32
            modifiedSteps: HelpersLib._toUint8Arr(bp.modifiedSteps)
        });
    }
    
    function renderForHumans(uint256 tokenId) external view returns(string memory) {
        _onlyBonsaiNFT();
        BonsaiProfile memory bp = _bonsaiState.getBonsaiProfile(tokenId);

        WateringStatus memory ws = _bonsaiState.wateringStatusForRender({lastWatered: bp.lastWatered, adjustedStartTime: bp.adjustedStartTime, watering: false});

        (
          Vars memory vars, // stack2deep makes you do weird things...
          uint256 maxSprouts
        ) = _getInitialDataForRender(bp, ws);

        string memory image = _renderOnchain(bp, vars, maxSprouts);

        unchecked{
        bytes memory b = new bytes(70000);
        assembly {
            mstore(b, 0)
        }

        _append(b, "{\"name\":\"bonSAI #",
            Strings.toString(tokenId));

        _append(b, "\",\"description\":\"Limited, generative art collection living entirely 'in-chain'.");

        _append(b, "\",\"attributes\":[");

        _append(b, "{\"trait_type\":\"seed\",\"value\":\"", Strings.toString(bp.seed));

        _append(b, "\"},{\"trait_type\":\"ratio\",\"value\":\"", 
            bytes(StringsExtended.toStringDecimal(bp.ratio, 18)));

        _append(b, "\"},{\"trait_type\":\"distance_to_PHI\",\"value\":\"", _distanceToPHI(bp.ratio));
        
        _append(b, "\"},{\"trait_type\":\"adjusted_start_time\",\"value\":\"", Strings.toString(bp.adjustedStartTime));

        _append(b, "\"},{\"trait_type\":\"trunk_number\",\"value\":\"", Strings.toString(bp.trunkSVGNumber));

        _append(b, "\"},{\"trait_type\":\"blossom_color\",\"value\":\"", 
            string((ws.healthStatus == HealthStatus.OK) ? _bytes32ToColorBytes(_getBlossomColor(bp.seed)) : bytes("none")));

        _append(b, "\"},{\"trait_type\":\"background_tint\",\"value\":\"", _bytes32ToColorBytes(_getBackgroundColor(bp.seed)));

        _append(b, "\"},{\"trait_type\":\"last_watered\",\"value\":\"", Strings.toString(ws.lastWatered));

        _append(b, "\"},{\"trait_type\":\"watering_status\",\"value\":\"", ws.status);

        _append(b, "\"},{\"trait_type\":\"growth_steps\",\"value\":\"",
            HelpersLib._buildStringArray(HelpersLib._toUint8Arr(bp.modifiedSteps)));

        _append(b, "\"},{\"trait_type\":\"note\",\"value\":\"may need to refresh metadata for latest growth.\"");

        _append(b, "}],\"image\":\"");
        _append(b, bytes(image));

        _append(b, bytes("\"}"));

        bytes memory bb = new bytes(70000);
        assembly {
            mstore(bb, 0)
        }
        _append(bb, "data:application/json;base64,",
            Base64.encode(b));

        return string(bb);
        }//uc
    }

    function _renderOnchain(BonsaiProfile memory bp, Vars memory vars, uint256 maxSprouts) public view returns(string memory) {
        unchecked{ // all math safe here
        
        uint256[][3] memory cache; // read/write/tmp

        // write cache
        cache[1] = new uint256[](_maxCacheSize(maxSprouts, MAX_BRANCHES));

        bytes memory b = new bytes(70000);
        assembly {
            mstore(b, 0)
        }

        _append(b, SSTORE2.read(_svgXMLPtrs[0]));

        _append(b, bytes(Strings.toString(bp.seed))); // background seed

        _append(b, SSTORE2.read(_svgXMLPtrs[1]));

        _append(b, bytes(Strings.toString(bp.seed))); // trunk seed
        
        _append(b, SSTORE2.read(_svgXMLPtrs[2]));

        _append(b, string(_bytes32ToColorBytes(_getBackgroundColor(bp.seed))), bytes("\" />"));

        _append(b, bytes(_getTrunkSVG(bp.trunkSVGNumber)));

        uint256 coordinates = _getCoordinatesForTrunk(bp.trunkSVGNumber);
        // coordinates // 16 bits for each coordinates and length
        // arranged: length, x, y
        HelpersLib._push(cache[1], coordinates); 
        cache[0] = cache[1]; // read = write
        // write cache
        cache[1] = new uint256[](cache[0].length);
        uint256 endCoordinates;
        
        // bounded by maxSprouts
        // start with initial base
        // loop foreach layer
        //   pick base -> numNewBranches 
        //             newBranch {length(baseLength), angle}
        //             draw and set end into base for next layer

        uint256 seed = bp.seed;
        uint256 numNewBranches;
        uint256 step;
        uint256 sprouts;
        uint256 ratio = bp.ratio;
        while (true) { // layer
            step = HelpersLib._getUint8(bp.modifiedSteps, vars.layer); // safe bc layer < 16 since breaks when layer == gradients.length below
            _append(b, bytes("<path d=\"")); // pathStart
            while ((coordinates = HelpersLib._pop(cache[0])) != type(uint256).max) { // sentinel value // base
                seed = HelpersLib._steppedHash(seed, step);
                numNewBranches = seed % MAX_BRANCHES;
                if (numNewBranches == 0 && vars.layer < 2) { // encourages growth of base limbs
                    while (numNewBranches == 0) {
                        seed = uint256(keccak256(abi.encodePacked(seed)));
                        numNewBranches = seed % MAX_BRANCHES;
                    } 
                }
                for (uint256 i; i < numNewBranches; ++i) {
                    ++sprouts;
                    if (sprouts == maxSprouts) break;
                    // def length, angle
                    endCoordinates = _getEndCoordinates(coordinates, seed, i, ratio);
                    HelpersLib._push(cache[1], endCoordinates);

                    // draw
                    _append(b, bytes(_draw(coordinates, endCoordinates)));
                }
                if (sprouts == maxSprouts) break;
            }
            // using single append due to s2d
            _append(b, bytes("\" stroke=\""));
            _append(b, _bytes32ToColorBytes(vars.gradients[vars.layer++]));

            _append(b, bytes("\" stroke-width=\""));
            _append(b, bytes(Strings.toString(vars.strokeWidth/ONE)));

            _append(b, bytes("."));
            _append(b, bytes(Strings.toString(vars.strokeWidth % ONE)));

            vars.strokeWidth = vars.strokeWidth * ONE/bp.ratio;
            if (vars.strokeWidth == 0) vars.strokeWidth = ONE;

            if (vars.layer < 3) {
                _append(b, "\" stroke-linecap=\"round\" fill=\"none\" filter=\"url(#filter1769)\"/>");
            } else {
                _append(b, "\" stroke-linecap=\"round\" fill=\"none\" filter=\"url(#filter5199)\"/>");
            }
            
            if (sprouts == maxSprouts || vars.layer == vars.gradients.length) break; // 2nd case is unlikely but possible
            cache[2] = cache[1]; // tmp = write
            cache[1] = cache[0]; // write = read
            cache[0] = cache[2]; // read = tmp
        }
        _append(b, bytes("</svg>"));

        bytes memory bb = new bytes(70000);
        assembly {
            mstore(bb, 0)
        }
        _append(bb, "data:image/svg+xml;base64,",
            Base64.encode(b));
        
        return string(bb);
        }//uc
    }

    // cheaper than bytes concat :)
    function _append(bytes memory dst, bytes memory src) private view {
      
        assembly {
            // resize

            let priorLength := mload(dst)
            
            mstore(dst, add(priorLength, mload(src)))
        
            // copy    

            pop(
                staticcall(
                  gas(), 4, 
                  add(src, 32), // src data start
                  mload(src), // src length 
                  add(dst, add(32, priorLength)), // dst write ptr
                  mload(dst)
                ) 
            )
        }
    }

    function _append(bytes memory dst, string memory src0, string memory src1) private view {
        _append(dst, src0, bytes(src1));
    }

    // cheaper than bytes concat :), two src params reduce gas cost from only one `priorLength` declaration
    function _append(bytes memory dst, string memory src0, bytes memory src1) private view {
      
        assembly {
            // resize

            let priorLength := mload(dst)
            
            mstore(dst, add(priorLength, mload(src0)))
        
            // copy    

            pop(
                staticcall(
                  gas(), 4, 
                  add(src0, 32), // src data start
                  mload(src0), // src0 length 
                  add(dst, add(32, priorLength)), // dst write ptr
                  mload(dst)
                ) 
            )

            // again :)
            priorLength := mload(dst)
            mstore(dst, add(priorLength, mload(src1)))
        
            // copy    

            pop(
                staticcall(
                  gas(), 4, 
                  add(src1, 32), // src data start
                  mload(src1), // src1 length 
                  add(dst, add(32, priorLength)), // dst write ptr
                  mload(dst)
                ) 
            )
        }
    }

    function _draw(uint256 coordinates, uint256 endCoordinates) private view returns(string memory) { 
        bytes19 _SYMBOLS = "0123456789abcdef ML";
        uint256 length;
        unchecked{
        for (uint256 i = 1; i < 3; ++i) {
            length += Math.log10(
                (coordinates >> (i*16)) & type(uint16).max
            ) + 1; 
           
        }
        for (uint256 i = 1; i < 3; ++i) {
            length += Math.log10(
                (endCoordinates >> (i*16)) & type(uint16).max
            ) + 1; 
        }
        length += 4; // M,_,L,_
        string memory buffer = new string(length);
        uint256 ptr;
        /// @solidity memory-safe-assembly
        assembly {
            ptr := add(buffer, add(32, length))
        }
        // note drawing is in reverse order
        uint256 value = (endCoordinates >> 32) & type(uint16).max;
        while (true) {
            --ptr;
            /// @solidity memory-safe-assembly
            assembly {
                mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
            }
            value /= 10;
            if (value == 0) break;
        }
        --ptr;
        assembly {
            mstore8(ptr, byte(16, _SYMBOLS)) // " "
        }
        value = (endCoordinates >> 16) & type(uint16).max;
        while (true) {
            --ptr;
            /// @solidity memory-safe-assembly
            assembly {
                mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
            }
            value /= 10;
            if (value == 0) break;
        }
        --ptr;
        assembly {
            mstore8(ptr, byte(18, _SYMBOLS)) // "L"
        }
        value = (coordinates >> 32) & type(uint16).max;
        while (true) {
            --ptr;
            /// @solidity memory-safe-assembly
            assembly {
                mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
            }
            value /= 10;
            if (value == 0) break;
        }
        --ptr;
        assembly {
            mstore8(ptr, byte(16, _SYMBOLS)) // " "
        }
        value = (coordinates >> 16) & type(uint16).max;
        while (true) {
            --ptr;
            /// @solidity memory-safe-assembly
            assembly {
                mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
            }
            value /= 10;
            if (value == 0) break;
        }
        --ptr;
        assembly {
            mstore8(ptr, byte(17, _SYMBOLS)) // "M"
        }
        return buffer;
        }//uc
    }

    function _bytes32ToColorBytes(bytes32 input) private pure returns(bytes memory ret) {
        ret = abi.encodePacked(input); 
        assembly {
            mstore(ret, 7) // #XXXXXX
        }
    }

    // getters

    function _distanceToPHI(uint64 ratio) private pure returns(string memory) {
        unchecked{
        uint256 difference;
        if (ratio > PHI) {
            difference = ratio - PHI; 
        } else {
            difference = PHI - ratio; 
        } 
        return StringsExtended.toStringDecimal(difference, 18);
        }//uc
    }
    
    function _getInitialDataForRender(BonsaiProfile memory bp, WateringStatus memory ws) private view returns(Vars memory vars, uint256 maxSprouts) {
        unchecked{
        vars.strokeWidth = 10**19;
        vars.gradients = _getGradients(ws, bp.seed);

        // this stunts the age and growth of plant according to health
        uint256 growthTime;
        if (ws.healthStatus != HealthStatus.OK) {
            growthTime = bp.lastWatered + 1 weeks - bp.adjustedStartTime; 
        } else { // ok
            growthTime = block.timestamp - bp.adjustedStartTime; 
            growthTime = (growthTime > 6 weeks) ? 6 weeks : growthTime;
        }
        maxSprouts = 36 * 365 * (growthTime) / (52 weeks); // tuned to keep rendering below 60mil gas = 2*GasLimit of 30mil
        }//uc
    }

    function _getCoordinatesForTrunk(uint8 trunkSVGNumber) private pure returns(uint256 coordinates) {
        (uint256 x, uint256 y) = _getTrunkInitialP1(trunkSVGNumber); 
        
        coordinates = 13_000; // length has 2 decimals

        coordinates |= x << 16;
        coordinates |= y << 32;
    }

    function _getEndCoordinates(
        uint256 coordinates, 
        uint256 seed, 
        uint256 secondSeed, 
        uint256 ratio
    ) private pure returns(uint256 endCoordinates) {
        seed = HelpersLib._steppedHash(seed, secondSeed);

        unchecked{ // it's all within range :)
        uint256 angle = (seed >> 128) % (5*PI/4);// take the 'ole top
        uint256 width = 8*(10**16);
        while (PI/2-width < angle && angle < PI/2+width) {
            seed = HelpersLib._steppedHash(seed, secondSeed);
            angle = (seed >> 128) % (5*PI/4);// take the 'ole top
        }

        if (angle > 9*PI/8) {
            angle = 2*PI - angle % (9*PI/8); // to effectively get angles from -PI/8 to 9PI/8
        }

        uint256 lastLength = coordinates & type(uint16).max;

        lastLength *= 10**16; // recall length is stored w 2 decimals

        uint256 length = lastLength * ONE / ratio;
        uint256 lengthVariance = seed % 10**17; // take the `ole bottom
        
        lengthVariance = lengthVariance * length / ONE;
        if (lengthVariance % 2 == 0) {
            length += lengthVariance;
        } else {
            length -= lengthVariance;
        }

        // now given the angle and length we can find x,y using trig lib
        uint256 x = (coordinates >> 16) & type(uint16).max;
        x *= 10**18;
        uint256 y = (coordinates >> 32) & type(uint16).max;
        y *= 10**18;
        
        // cases to guard against overflow and distortion
        if (angle <= PI/2) {
            x = uint256(int256(x) + int256(length) * Trigonometry.cos(angle) / 10**18);
            y = uint256(int256(y) - int256(length) * Trigonometry.sin(angle) / 10**18); // "-" because orientation of y axis
        } else if (angle <= PI) {
            int256 uncastX = int256(x) + int256(length) * Trigonometry.cos(angle) / 10**18;
            if (uncastX < 0) {
                // then just using PI/2 as angle instead to prevent trekking further left
                // pass through x=x
            } else {
                x = uint256(uncastX);
            }
            y = uint256(int256(y) - int256(length) * Trigonometry.sin(angle) / 10**18); // "-" because orientation of y axis
        } else if (angle <= 3*PI/2) {
            int256 uncastX = int256(x) + int256(length) * Trigonometry.cos(angle) / 10**18;
            if (uncastX < 0) {
            } else {
                x = uint256(uncastX);
            }
            int256 uncastY = int256(y) - int256(length) * Trigonometry.sin(angle) / 10**18; // "-" because orientation of y axis
            if (uncastY < 0) {
                // pass through y=y as above
            } else {
                y = uint256(uncastY);
            }
        } else {
            x = uint256(int256(x) + int256(length) * Trigonometry.cos(angle) / 10**18);
            int256 uncastY = int256(y) - int256(length) * Trigonometry.sin(angle) / 10**18; // "-" because orientation of y axis
            if (uncastY < 0) {
                // pass through y=y as above
            } else {
                y = uint256(uncastY);
            }
        }
        x /= 10**18;
        y /= 10**18;

        length /= 10**16; // convert back to 10**2

        endCoordinates = length;
        endCoordinates |= (x & type(uint16).max) << 16;
        endCoordinates |= (y & type(uint16).max) << 32;

        }//uc
    }

    function _getBackgroundColor(uint256 seed) private pure returns(bytes32) {
        seed = uint256(keccak256(abi.encodePacked(seed, "background"))) % 100; // percentile
        if (seed > 54) { // [55, 99]
            return "#800080";
        } else if (seed > 27) { // [28, 54]
            return "#0000FF";
        } else if (seed > 9) { // [10, 27]
            return "#00FF00";
        } else if (seed > 3) { // [4, 9]
            return "#FFFF00";
        } else if (seed > 0) { // [1, 3]
            return "#FFA500";
        } else { // seed == 0 
            return "#FF0000";
        }
    }

    function _getGradients(WateringStatus memory ws, uint256 seed) private pure returns(bytes32[12] memory gradients) {
        HealthStatus hs = ws.healthStatus;
        unchecked{ // just the loops
        if (hs == HealthStatus.DEAD) {
            // dead
            for (uint256 i; i < gradients.length; ++i) {
                gradients[i] = "#000000";
            } 
        } else if (hs == HealthStatus.DRY) {
            // dried out but needs watering
            for (uint256 i; i < gradients.length; ++i) {
                gradients[i] = "#724518";
            } 
        } else {
            // healthy as hare
            gradients = [
              bytes32("#724518"), // for the trunk
              bytes32("#724518"),
              bytes32("#604529"),
              bytes32("#896701"),
              bytes32("#018923"), // light green
              bytes32("#006400"), // dark green
              _getBlossomColor(seed), // will be reset to pink or red rare 
              bytes32("#fff000"), // yellow
              bytes32("#ff0000"), // red
              bytes32("#fff000"), // yellow
              bytes32("#FF007F"), // pink 
              bytes32("#000000")]; // should never realistically make it this far
        }
        }//uc
    }

    function _getBlossomColor(uint256 seed) private pure returns(bytes32 blossomColor) {
        seed = uint256(keccak256(abi.encodePacked(seed, "blossom"))) % 100;
        if (seed == 0) {
          return "#FF0000"; // red
        } else if (seed < 10) {
          return "#0000FF"; // blue
        } // else
        return "#890189"; // purple
    }

    function _getTrunkSVG(uint256 trunkType) private view returns(string memory trunkSVG) {
        // unchecked. assumes the owner sets all the trunkType svgs
        return string(SSTORE2.read(_trunkTypePtrs[trunkType]));
    }

    function _getTrunkInitialP1(uint256 trunkType) private pure returns(uint256 x, uint256 y) {
          if (trunkType == 0) {
              x = 260; 
              y = 295;
          } else if (trunkType == 1) {
              x = 240; 
              y = 328;
          } else if (trunkType == 2) {
              x = 238; 
              y = 285;
          } else if (trunkType == 3) {
              x = 260; 
              y = 300;
          } else if (trunkType == 4) {
              x = 240; 
              y = 305;
          } else if (trunkType == 5) {
              x = 220; 
              y = 290;
          } else if (trunkType == 6) {
              x = 195; 
              y = 290;
          } else if (trunkType == 7) {
              x = 240; 
              y = 287;
          } else if (trunkType == 8) {
              x = 205; 
              y = 315;
          } else if (trunkType == 9) {
              x = 200; 
              y = 283;
          } else if (trunkType == 10) {
              x = 260; 
              y = 289;
          } else if (trunkType == 11) {
              x = 170; 
              y = 310; 
          }
    }
}