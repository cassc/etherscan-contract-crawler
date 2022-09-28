// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "../helper/U128Math.sol";

library LiquidityMath {
    using U128Math for uint128;

    // get the pool quote ratio
    // used to calculate the base amount transfer to user
    // from the totalUserLiquidityInQuote
    function quoteOut(
        uint128 quoteLiquidity,
        uint128 totalQuoteDeposited,
        uint128 totalPoolLiquidityQ
    ) internal pure returns (uint256) {
        // quoteOut = totalQuoteDeposited * quoteRatio
        // quoteRatio = quoteLiquidity / poolLiquidityInQuote
        // or quoteRatio = quoteLiquidity / (baseLiquidity * currentPrice + quoteLiquidity)
        // convert to 256 bits, avoid overflow
        return
            (quoteLiquidity.toU256() * totalQuoteDeposited.toU256()) /
            totalPoolLiquidityQ.toU256();
    }

    // get the pool base ratio
    // used to calculate the base amount transfer to user
    // from the totalUserLiquidityInQuote
    function baseOut(
        uint128 baseLiquidity,
        uint128 totalQuoteDeposited,
        uint128 totalPoolLiquidityQ
    ) internal pure returns (uint256) {
        //  baseOut = totalQuoteDeposited * baseRatio
        // while baseRatio = baseLiquidity / poolLiquidityInQuote
        // convert to 256 bits, avoid overflow
        return
            (baseLiquidity.toU256() * totalQuoteDeposited.toU256()) /
            totalPoolLiquidityQ.toU256();
    }

    // in case of the rounding issues, if liquidity < removeAmount returns 0
    function safeSubLiquidity(uint128 liquidity, uint128 removeAmount)
        internal
        pure
        returns (uint128)
    {
        if (liquidity >= removeAmount) {
            return liquidity - removeAmount;
        }
        return 0;
    }

    function absIn128(int128 n) internal pure returns (uint128) {
        return uint128(n > 0 ? n : -n);
    }

    function safeAdjustLiquidity(uint128 liquidity, int128 adjustAmount)
        internal
        pure
        returns (uint128)
    {
        int128 c = int128(liquidity) + adjustAmount;
        if (c > 0) {
            return uint128(c);
        }
        return 0;
    }
}