// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./ABDKMath64x64.sol";

/**
 * Library with utility functions for CLR
 */
library Utils {
    using SafeMath for uint256;

    struct AmountsMinted {
        uint256 amount0ToMint;
        uint256 amount1ToMint;
        uint256 amount0Minted;
        uint256 amount1Minted;
    }

    /**
     * Helper function to calculate how much to swap when
     * staking or withdrawing from Uni V3 Pools
     * Goal of this function is to calibrate the staking tokens amounts
     * When we want to stake, for example, 100 token0 and 10 token1
     * But pool price demands 100 token0 and 40 token1
     * We cannot directly stake 100 t0 and 10 t1, so we swap enough
     * to be able to stake the value of 100 t0 and 10 t1
     */
    function calculateSwapAmount(
        AmountsMinted memory amountsMinted,
        int128 liquidityRatio,
        uint256 midPrice
    ) internal pure returns (uint256 swapAmount, bool swapSign) {
        // formula is more complicated than xU3LP case
        // it includes the asset prices, and considers the swap impact on the pool
        // base formula is this:
        // n - swap amt, x - amount 0 to mint, y - amount 1 to mint,
        // z - amount 0 minted, t - amount 1 minted, p0 - pool mid price
        // l - liquidity ratio (current mint liquidity vs total pool liq)
        // (X - n) / (Y + n * p0) = (Z + l * n) / (T - l * n * p0) ->
        // n = (X * T - Y * Z) / (p0 * l * X + p0 * Z + l * Y + T)
        int128 midPrice64x64 = ABDKMath64x64.divu(midPrice, 1e12);
        uint256 denominator = ABDKMath64x64
            .mulu(
                ABDKMath64x64.mul(midPrice64x64, liquidityRatio),
                amountsMinted.amount0ToMint
            )
            .add(ABDKMath64x64.mulu(midPrice64x64, amountsMinted.amount0Minted))
            .add(
                ABDKMath64x64.mulu(liquidityRatio, amountsMinted.amount1ToMint)
            )
            .add(amountsMinted.amount1Minted);
        uint256 a = muldiv(
            amountsMinted.amount0ToMint,
            amountsMinted.amount1Minted,
            denominator
        );
        uint256 b = muldiv(
            amountsMinted.amount1ToMint,
            amountsMinted.amount0Minted,
            denominator
        );
        swapAmount = a >= b ? a - b : b - a;
        swapSign = a >= b ? true : false;
    }

    /**
     * @dev multiply a and b and divide by denominator
     * @dev Taken from here: https://xn--2-umb.com/21/muldiv/index.html"
     */
    function muldiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // Handle division by zero
        require(denominator > 0);

        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remiander Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Short circuit 256 by 256 division
        // This saves gas when a * b is small, at the cost of making the
        // large case a bit more expensive. Depending on your use case you
        // may want to remove this short circuit and always go through the
        // 512 bit path.
        if (prod1 == 0) {
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Handle overflow, the result must be < 2**256
        require(prod1 < denominator);

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        // Note mulmod(_, _, 0) == 0
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1 unless denominator is zero, then twos is zero.
        uint256 twos = -denominator & denominator;
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        // If denominator is zero the inverse starts with 2
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson itteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256
        // If denominator is zero, inv is now 128

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    // Subtract two numbers and return absolute value
    function subAbs(uint256 amount0, uint256 amount1)
        internal
        pure
        returns (uint256)
    {
        return amount0 >= amount1 ? amount0 - amount1 : amount1 - amount0;
    }
}