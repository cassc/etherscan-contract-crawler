/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

import "../helper/FixedPoint128.sol";

/// @title All formulas used in the AMM
library LiquidityMath {
    /// @notice calculate base real from virtual
    /// @param sqrtMaxPip sqrt the max price
    /// @param xVirtual the base virtual
    /// @param sqrtCurrentPrice sqrt the current price
    /// @return the base real
    function calculateBaseReal(
        uint128 sqrtMaxPip,
        uint128 xVirtual,
        uint128 sqrtCurrentPrice
    ) internal pure returns (uint128) {
        if (sqrtCurrentPrice == sqrtMaxPip) {
            return 0;
        }
        return
            uint128(
                (uint256(sqrtMaxPip) * uint256(xVirtual)) /
                    (uint256(sqrtMaxPip) - uint256(sqrtCurrentPrice))
            );
    }

    /// @notice calculate quote real from virtual
    /// @param sqrtMinPip sqrt the max price
    /// @param yVirtual the quote virtual
    /// @param sqrtCurrentPrice sqrt the current price
    /// @return the quote real
    function calculateQuoteReal(
        uint128 sqrtMinPip,
        uint128 yVirtual,
        uint128 sqrtCurrentPrice
    ) internal pure returns (uint128) {
        if (sqrtCurrentPrice == sqrtMinPip) {
            return 0;
        }
        return
            uint128(
                (uint256(sqrtCurrentPrice) * uint256(yVirtual)) /
                    (uint256(sqrtCurrentPrice) - uint256(sqrtMinPip))
            );
    }

    /// @title These functions below are used to calculate the amount asset when SELL

    /// @notice calculate base amount with target price when sell
    /// @param sqrtPriceTarget sqrt the target price
    /// @param quoteReal the quote real
    /// @param sqrtCurrentPrice sqrt the current price
    /// @return the base amount
    function calculateBaseWithPriceWhenSell(
        uint128 sqrtPriceTarget,
        uint128 quoteReal,
        uint128 sqrtCurrentPrice
    ) internal pure returns (uint128) {
        return
            uint128(
                (FixedPoint128.BUFFER *
                    (uint256(quoteReal) *
                        (uint256(sqrtCurrentPrice) -
                            uint256(sqrtPriceTarget)))) /
                    (uint256(sqrtPriceTarget) * uint256(sqrtCurrentPrice) ** 2)
            );
    }

    /// @notice calculate quote amount with target price when sell
    /// @param sqrtPriceTarget sqrt the target price
    /// @param quoteReal the quote real
    /// @param sqrtCurrentPrice sqrt the current price
    /// @return the quote amount
    function calculateQuoteWithPriceWhenSell(
        uint128 sqrtPriceTarget,
        uint128 quoteReal,
        uint128 sqrtCurrentPrice
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(quoteReal) *
                    (uint256(sqrtCurrentPrice) - uint256(sqrtPriceTarget))) /
                    uint256(sqrtCurrentPrice)
            );
    }

    /// @notice calculate base amount with target price when buy
    /// @param sqrtPriceTarget sqrt the target price
    /// @param baseReal the quote real
    /// @param sqrtCurrentPrice sqrt the current price
    /// @return the base amount
    function calculateBaseWithPriceWhenBuy(
        uint128 sqrtPriceTarget,
        uint128 baseReal,
        uint128 sqrtCurrentPrice
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(baseReal) *
                    (uint256(sqrtPriceTarget) - uint256(sqrtCurrentPrice))) /
                    uint256(sqrtPriceTarget)
            );
    }

    /// @notice calculate quote amount with target price when buy
    /// @param sqrtPriceTarget sqrt the target price
    /// @param baseReal the quote real
    /// @param sqrtCurrentPrice sqrt the current price
    /// @return the quote amount
    function calculateQuoteWithPriceWhenBuy(
        uint128 sqrtPriceTarget,
        uint128 baseReal,
        uint128 sqrtCurrentPrice
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(baseReal) *
                    uint256(sqrtCurrentPrice) *
                    (uint256(sqrtPriceTarget) - uint256(sqrtCurrentPrice))) /
                    FixedPoint128.BUFFER
            );
    }

    /// @notice calculate index pip range
    /// @param pip the pip want to calculate
    /// @param pipRange the range of pair
    /// @return the index pip range
    function calculateIndexPipRange(
        uint128 pip,
        uint128 pipRange
    ) internal pure returns (uint256) {
        return uint256(pip / pipRange);
    }

    /// @notice calculate max in min pip in index
    /// @param indexedPipRange the index pip range
    /// @param pipRange the range of pair
    /// @return pipMin the min pip in index
    /// @return pipMax the max pip in index
    function calculatePipRange(
        uint32 indexedPipRange,
        uint128 pipRange
    ) internal pure returns (uint128 pipMin, uint128 pipMax) {
        pipMin = indexedPipRange == 0 ? 1 : indexedPipRange * pipRange;
        pipMax = pipMin + pipRange - 1;
    }

    /// @notice calculate quote and quote amount with no target price when sell
    /// @param sqrtK the sqrt k- mean liquidity
    /// @param amountReal amount real
    /// @param amount amount
    /// @return the amount base or quote
    function calculateBaseBuyAndQuoteSellWithoutTargetPrice(
        uint128 sqrtK,
        uint128 amountReal,
        uint128 amount
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(amount) * uint256(amountReal) ** 2) /
                    (uint256(sqrtK) ** 2 + amount * uint256(amountReal))
            );
    }

    /// @notice calculate quote and quote amount with no target price when buy
    /// @param sqrtK the sqrt k- mean liquidity
    /// @param amountReal amount real
    /// @param amount amount
    /// @return the amount base or quote
    function calculateQuoteBuyAndBaseSellWithoutTargetPrice(
        uint128 sqrtK,
        uint128 amountReal,
        uint128 amount
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(amount) * uint256(sqrtK) ** 2) /
                    (uint256(amountReal) *
                        (uint256(amountReal) - uint256(amount)))
            );
    }

    /// @notice calculate K ( liquidity) with quote real
    /// @param quoteReal the quote real
    /// @param sqrtPriceMax sqrt of price max
    function calculateKWithQuote(
        uint128 quoteReal,
        uint128 sqrtPriceMax
    ) internal pure returns (uint256) {
        return
            (uint256(quoteReal) ** 2 / uint256(sqrtPriceMax)) *
            (FixedPoint128.BUFFER / uint256(sqrtPriceMax));
    }

    /// @notice calculate K ( liquidity) with base real
    /// @param baseReal the quote real
    /// @param sqrtPriceMin sqrt of price max
    function calculateKWithBase(
        uint128 baseReal,
        uint128 sqrtPriceMin
    ) internal pure returns (uint256) {
        return
            (uint256(baseReal) ** 2 / FixedPoint128.HALF_BUFFER) *
            (uint256(sqrtPriceMin) ** 2 / FixedPoint128.HALF_BUFFER);
    }

    /// @notice calculate K ( liquidity) with base real and quote ral
    /// @param baseReal the quote real
    /// @param baseReal the base real
    function calculateKWithBaseAndQuote(
        uint128 quoteReal,
        uint128 baseReal
    ) internal pure returns (uint256) {
        return uint256(quoteReal) * uint256(baseReal);
    }

    /// @notice calculate the liquidity
    /// @param amountReal the amount real
    /// @param sqrtPrice sqrt of price
    /// @param isBase true if base, false if quote
    /// @return the liquidity
    function calculateLiquidity(
        uint128 amountReal,
        uint128 sqrtPrice,
        bool isBase
    ) internal pure returns (uint256) {
        if (isBase) {
            return uint256(amountReal) * uint256(sqrtPrice);
        } else {
            return uint256(amountReal) / uint256(sqrtPrice);
        }
    }

    /// @notice calculate base by the liquidity
    /// @param liquidity the liquidity
    /// @param sqrtPriceMax sqrt of price max
    /// @param sqrtPrice  sqrt of current price
    /// @return the base amount
    function calculateBaseByLiquidity(
        uint128 liquidity,
        uint128 sqrtPriceMax,
        uint128 sqrtPrice
    ) internal pure returns (uint128) {
        return
            uint128(
                (FixedPoint128.HALF_BUFFER *
                    uint256(liquidity) *
                    (uint256(sqrtPriceMax) - uint256(sqrtPrice))) /
                    (uint256(sqrtPrice) * uint256(sqrtPriceMax))
            );
    }

    /// @notice calculate quote by the liquidity
    /// @param liquidity the liquidity
    /// @param sqrtPriceMin sqrt of price min
    /// @param sqrtPrice  sqrt of current price
    /// @return the quote amount
    function calculateQuoteByLiquidity(
        uint128 liquidity,
        uint128 sqrtPriceMin,
        uint128 sqrtPrice
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(liquidity) *
                    (uint256(sqrtPrice) - uint256(sqrtPriceMin))) /
                    FixedPoint128.HALF_BUFFER
            );
    }

    /// @notice calculate base real by the liquidity
    /// @param liquidity the liquidity
    /// @param totalLiquidity the total liquidity of liquidity info
    /// @param totalBaseReal total base real of liquidity
    /// @return the base real
    function calculateBaseRealByLiquidity(
        uint128 liquidity,
        uint128 totalLiquidity,
        uint128 totalBaseReal
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(liquidity) * totalBaseReal) / uint256(totalLiquidity)
            );
    }

    /// @notice calculate quote real by the liquidity
    /// @param liquidity the liquidity
    /// @param totalLiquidity the total liquidity of liquidity info
    /// @param totalQuoteReal total quote real of liquidity
    /// @return the quote real
    function calculateQuoteRealByLiquidity(
        uint128 liquidity,
        uint128 totalLiquidity,
        uint128 totalQuoteReal
    ) internal pure returns (uint128) {
        return
            uint128(
                (uint256(liquidity) * totalQuoteReal) / uint256(totalLiquidity)
            );
    }

    /// @notice calculate quote virtual from base virtual
    /// @param baseVirtualAmount the base virtual amount
    /// @param sqrtCurrentPrice the sqrt of current price
    /// @param sqrtMaxPip sqrt of max pip
    /// @param sqrtMinPip sqrt of min pip
    /// @return quoteVirtualAmount the quote virtual amount
    function calculateQuoteVirtualAmountFromBaseVirtualAmount(
        uint128 baseVirtualAmount,
        uint128 sqrtCurrentPrice,
        uint128 sqrtMaxPip,
        uint128 sqrtMinPip
    ) internal pure returns (uint128 quoteVirtualAmount) {
        return
            (baseVirtualAmount *
                sqrtCurrentPrice *
                (sqrtCurrentPrice - sqrtMinPip)) /
            (sqrtMaxPip * sqrtCurrentPrice);
    }

    /// @notice calculate base virtual from quote virtual
    /// @param quoteVirtualAmount the quote virtual amount
    /// @param sqrtCurrentPrice the sqrt of current price
    /// @param sqrtMaxPip sqrt of max pip
    /// @param sqrtMinPip sqrt of min pip
    /// @return  baseVirtualAmount the base virtual amount
    function calculateBaseVirtualAmountFromQuoteVirtualAmount(
        uint128 quoteVirtualAmount,
        uint128 sqrtCurrentPrice,
        uint128 sqrtMaxPip,
        uint128 sqrtMinPip
    ) internal pure returns (uint128 baseVirtualAmount) {
        return
            (quoteVirtualAmount *
                sqrtCurrentPrice *
                (sqrtCurrentPrice - sqrtMinPip)) /
            ((sqrtCurrentPrice - sqrtMinPip) * sqrtCurrentPrice * sqrtMaxPip);
    }
}