// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

/* solhint-disable */
/// @dev Common mathematical functions used in both PRBMathSD59x18 and PRBMathUD60x18. Note that this shared library
/// does not always assume the signed 59.18-decimal fixed-point or the unsigned 60.18-decimal fixed-point
// representation. When it does not, it is annonated in the function's NatSpec documentation.
/// @author Paul Razvan Berg
library PRBMathCommon {
    /// @dev How many trailing decimals can be represented.
    uint256 internal constant SCALE = 1e18;

    /// @notice Calculates the binary exponent of x using the binary fraction method.
    /// @dev Uses 128.128-bit fixed-point numbers - it is the most efficient way.
    /// @param x The exponent as an unsigned 128.128-bit fixed-point number.
    /// @return result The result as an unsigned 60x18 decimal fixed-point number.
    function exp2(uint256 x) internal pure returns (uint256 result) {
        unchecked {
            // Start from 0.5 in the 128.128-bit fixed-point format. We need to use uint256 because the intermediary
            // may get very close to 2^256, which doesn't fit in int256.
            result = 0x80000000000000000000000000000000;

            // Multiply the result by root(2, 2^-i) when the bit at position i is 1. None of the intermediary results overflows
            // because the initial result is 2^127 and all magic factors are less than 2^129.
            if (x & 0x80000000000000000000000000000000 > 0) result = (result * 0x16A09E667F3BCC908B2FB1366EA957D3E) >> 128;
            if (x & 0x40000000000000000000000000000000 > 0) result = (result * 0x1306FE0A31B7152DE8D5A46305C85EDED) >> 128;
            if (x & 0x20000000000000000000000000000000 > 0) result = (result * 0x1172B83C7D517ADCDF7C8C50EB14A7920) >> 128;
            if (x & 0x10000000000000000000000000000000 > 0) result = (result * 0x10B5586CF9890F6298B92B71842A98364) >> 128;
            if (x & 0x8000000000000000000000000000000 > 0) result = (result * 0x1059B0D31585743AE7C548EB68CA417FE) >> 128;
            if (x & 0x4000000000000000000000000000000 > 0) result = (result * 0x102C9A3E778060EE6F7CACA4F7A29BDE9) >> 128;
            if (x & 0x2000000000000000000000000000000 > 0) result = (result * 0x10163DA9FB33356D84A66AE336DCDFA40) >> 128;
            if (x & 0x1000000000000000000000000000000 > 0) result = (result * 0x100B1AFA5ABCBED6129AB13EC11DC9544) >> 128;
            if (x & 0x800000000000000000000000000000 > 0) result = (result * 0x10058C86DA1C09EA1FF19D294CF2F679C) >> 128;
            if (x & 0x400000000000000000000000000000 > 0) result = (result * 0x1002C605E2E8CEC506D21BFC89A23A011) >> 128;
            if (x & 0x200000000000000000000000000000 > 0) result = (result * 0x100162F3904051FA128BCA9C55C31E5E0) >> 128;
            if (x & 0x100000000000000000000000000000 > 0) result = (result * 0x1000B175EFFDC76BA38E31671CA939726) >> 128;
            if (x & 0x80000000000000000000000000000 > 0) result = (result * 0x100058BA01FB9F96D6CACD4B180917C3E) >> 128;
            if (x & 0x40000000000000000000000000000 > 0) result = (result * 0x10002C5CC37DA9491D0985C348C68E7B4) >> 128;
            if (x & 0x20000000000000000000000000000 > 0) result = (result * 0x1000162E525EE054754457D5995292027) >> 128;
            if (x & 0x10000000000000000000000000000 > 0) result = (result * 0x10000B17255775C040618BF4A4ADE83FD) >> 128;
            if (x & 0x8000000000000000000000000000 > 0) result = (result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAC) >> 128;
            if (x & 0x4000000000000000000000000000 > 0) result = (result * 0x100002C5C89D5EC6CA4D7C8ACC017B7CA) >> 128;
            if (x & 0x2000000000000000000000000000 > 0) result = (result * 0x10000162E43F4F831060E02D839A9D16D) >> 128;
            if (x & 0x1000000000000000000000000000 > 0) result = (result * 0x100000B1721BCFC99D9F890EA06911763) >> 128;
            if (x & 0x800000000000000000000000000 > 0) result = (result * 0x10000058B90CF1E6D97F9CA14DBCC1629) >> 128;
            if (x & 0x400000000000000000000000000 > 0) result = (result * 0x1000002C5C863B73F016468F6BAC5CA2C) >> 128;
            if (x & 0x200000000000000000000000000 > 0) result = (result * 0x100000162E430E5A18F6119E3C02282A6) >> 128;
            if (x & 0x100000000000000000000000000 > 0) result = (result * 0x1000000B1721835514B86E6D96EFD1BFF) >> 128;
            if (x & 0x80000000000000000000000000 > 0) result = (result * 0x100000058B90C0B48C6BE5DF846C5B2F0) >> 128;
            if (x & 0x40000000000000000000000000 > 0) result = (result * 0x10000002C5C8601CC6B9E94213C72737B) >> 128;
            if (x & 0x20000000000000000000000000 > 0) result = (result * 0x1000000162E42FFF037DF38AA2B219F07) >> 128;
            if (x & 0x10000000000000000000000000 > 0) result = (result * 0x10000000B17217FBA9C739AA5819F44FA) >> 128;
            if (x & 0x8000000000000000000000000 > 0) result = (result * 0x1000000058B90BFCDEE5ACD3C1CEDC824) >> 128;
            if (x & 0x4000000000000000000000000 > 0) result = (result * 0x100000002C5C85FE31F35A6A30DA1BE51) >> 128;
            if (x & 0x2000000000000000000000000 > 0) result = (result * 0x10000000162E42FF0999CE3541B9FFFD0) >> 128;
            if (x & 0x1000000000000000000000000 > 0) result = (result * 0x100000000B17217F80F4EF5AADDA45554) >> 128;
            if (x & 0x800000000000000000000000 > 0) result = (result * 0x10000000058B90BFBF8479BD5A81B51AE) >> 128;
            if (x & 0x400000000000000000000000 > 0) result = (result * 0x1000000002C5C85FDF84BD62AE30A74CD) >> 128;
            if (x & 0x200000000000000000000000 > 0) result = (result * 0x100000000162E42FEFB2FED257559BDAA) >> 128;
            if (x & 0x100000000000000000000000 > 0) result = (result * 0x1000000000B17217F7D5A7716BBA4A9AF) >> 128;
            if (x & 0x80000000000000000000000 > 0) result = (result * 0x100000000058B90BFBE9DDBAC5E109CCF) >> 128;
            if (x & 0x40000000000000000000000 > 0) result = (result * 0x10000000002C5C85FDF4B15DE6F17EB0E) >> 128;
            if (x & 0x20000000000000000000000 > 0) result = (result * 0x1000000000162E42FEFA494F1478FDE05) >> 128;
            if (x & 0x10000000000000000000000 > 0) result = (result * 0x10000000000B17217F7D20CF927C8E94D) >> 128;
            if (x & 0x8000000000000000000000 > 0) result = (result * 0x1000000000058B90BFBE8F71CB4E4B33E) >> 128;
            if (x & 0x4000000000000000000000 > 0) result = (result * 0x100000000002C5C85FDF477B662B26946) >> 128;
            if (x & 0x2000000000000000000000 > 0) result = (result * 0x10000000000162E42FEFA3AE53369388D) >> 128;
            if (x & 0x1000000000000000000000 > 0) result = (result * 0x100000000000B17217F7D1D351A389D41) >> 128;
            if (x & 0x800000000000000000000 > 0) result = (result * 0x10000000000058B90BFBE8E8B2D3D4EDF) >> 128;
            if (x & 0x400000000000000000000 > 0) result = (result * 0x1000000000002C5C85FDF4741BEA6E77F) >> 128;
            if (x & 0x200000000000000000000 > 0) result = (result * 0x100000000000162E42FEFA39FE95583C3) >> 128;
            if (x & 0x100000000000000000000 > 0) result = (result * 0x1000000000000B17217F7D1CFB72B45E3) >> 128;
            if (x & 0x80000000000000000000 > 0) result = (result * 0x100000000000058B90BFBE8E7CC35C3F2) >> 128;
            if (x & 0x40000000000000000000 > 0) result = (result * 0x10000000000002C5C85FDF473E242EA39) >> 128;
            if (x & 0x20000000000000000000 > 0) result = (result * 0x1000000000000162E42FEFA39F02B772C) >> 128;
            if (x & 0x10000000000000000000 > 0) result = (result * 0x10000000000000B17217F7D1CF7D83C1A) >> 128;
            if (x & 0x8000000000000000000 > 0) result = (result * 0x1000000000000058B90BFBE8E7BDCBE2E) >> 128;
            if (x & 0x4000000000000000000 > 0) result = (result * 0x100000000000002C5C85FDF473DEA871F) >> 128;
            if (x & 0x2000000000000000000 > 0) result = (result * 0x10000000000000162E42FEFA39EF44D92) >> 128;
            if (x & 0x1000000000000000000 > 0) result = (result * 0x100000000000000B17217F7D1CF79E949) >> 128;
            if (x & 0x800000000000000000 > 0) result = (result * 0x10000000000000058B90BFBE8E7BCE545) >> 128;
            if (x & 0x400000000000000000 > 0) result = (result * 0x1000000000000002C5C85FDF473DE6ECA) >> 128;
            if (x & 0x200000000000000000 > 0) result = (result * 0x100000000000000162E42FEFA39EF366F) >> 128;
            if (x & 0x100000000000000000 > 0) result = (result * 0x1000000000000000B17217F7D1CF79AFA) >> 128;
            if (x & 0x80000000000000000 > 0) result = (result * 0x100000000000000058B90BFBE8E7BCD6E) >> 128;
            if (x & 0x40000000000000000 > 0) result = (result * 0x10000000000000002C5C85FDF473DE6B3) >> 128;
            if (x & 0x20000000000000000 > 0) result = (result * 0x1000000000000000162E42FEFA39EF359) >> 128;
            if (x & 0x10000000000000000 > 0) result = (result * 0x10000000000000000B17217F7D1CF79AC) >> 128;

            // Multiply the result by the integer part 2^n + 1. We have to shift by one bit extra because we have already divided
            // by two when we set the result equal to 0.5 above.
            result = result << ((x >> 128) + 1);

            // Convert the result to the signed 60.18-decimal fixed-point format.
            result = PRBMathCommon.mulDiv(result, 1e18, 2**128);
        }
    }

    /// @notice Calculates floor(x*y÷denominator) with full precision.
    ///
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv.
    ///
    /// Requirements:
    /// - The denominator cannot be zero.
    /// - The result must fit within uint256.
    ///
    /// Caveats:
    /// - This function does not work with fixed-point numbers.
    ///
    /// @param x The multiplicand as an uint256.
    /// @param y The multiplier as an uint256.
    /// @param denominator The divisor as an uint256.
    /// @return result The result as an uint256.
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2**256 and mod 2**256 - 1, then use
        // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0.
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(x, y, not(0))
            prod0 := mul(x, y)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256. Also prevents denominator == 0.
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0].
        uint256 remainder;
        assembly {
            // Compute remainder using mulmod.
            remainder := mulmod(x, y, denominator)

            // Subtract 256 bit number from 512 bit number
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
        // See https://cs.stackexchange.com/q/138556/92363.
        unchecked {
            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 lpotdod = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by lpotdod.
                denominator := div(denominator, lpotdod)

                // Divide [prod1 prod0] by lpotdod.
                prod0 := div(prod0, lpotdod)

                // Flip lpotdod such that it is 2**256 / lpotdod. If lpotdod is zero, then it becomes one.
                lpotdod := add(div(sub(0, lpotdod), lpotdod), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * lpotdod;

            // Invert denominator mod 2**256. Now that denominator is an odd number, it has an inverse modulo 2**256 such
            // that denominator * inv = 1 mod 2**256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inverse = (3 * denominator) ^ 2;

            // Now use Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2**8
            inverse *= 2 - denominator * inverse; // inverse mod 2**16
            inverse *= 2 - denominator * inverse; // inverse mod 2**32
            inverse *= 2 - denominator * inverse; // inverse mod 2**64
            inverse *= 2 - denominator * inverse; // inverse mod 2**128
            inverse *= 2 - denominator * inverse; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2**256. Since the precoditions guarantee that the outcome is
            // less than 2**256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }
}
/* solhint-enable */