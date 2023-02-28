/**
 * @author Musket
 */
// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

library Liquidity {
    struct Info {
        uint128 sqrtMaxPip;
        uint128 sqrtMinPip;
        uint128 quoteReal;
        uint128 baseReal;
        uint32 indexedPipRange;
        uint256 feeGrowthBase;
        uint256 feeGrowthQuote;
        uint128 sqrtK;
    }

    /// @notice Define the new pip range when the first time add liquidity
    /// @param self the liquidity info
    /// @param sqrtMaxPip the max pip
    /// @param sqrtMinPip the min pip
    /// @param indexedPipRange the index of liquidity info
    function initNewPipRange(
        Liquidity.Info storage self,
        uint128 sqrtMaxPip,
        uint128 sqrtMinPip,
        uint32 indexedPipRange
    ) internal {
        self.sqrtMaxPip = sqrtMaxPip;
        self.sqrtMinPip = sqrtMinPip;
        self.indexedPipRange = indexedPipRange;
    }

    /// @notice update the liquidity info when add liquidity
    /// @param self the liquidity info
    /// @param updater of struct Liquidity.Info, this is new value of liquidity info
    function updateRangeLiquidity(
        Liquidity.Info storage self,
        Liquidity.Info memory updater
    ) internal {
        if (self.sqrtK == 0) {
            self.sqrtMaxPip = updater.sqrtMaxPip;
            self.sqrtMinPip = updater.sqrtMinPip;
            self.indexedPipRange = updater.indexedPipRange;
        }
        self.quoteReal = updater.quoteReal;
        self.baseReal = updater.baseReal;
        self.sqrtK = updater.sqrtK;
    }

    /// @notice growth fee base and quote
    /// @param self the liquidity info
    /// @param feeGrowthBase the growth of base
    /// @param feeGrowthQuote the growth of base
    function updateFeeGrowth(
        Liquidity.Info storage self,
        uint256 feeGrowthBase,
        uint256 feeGrowthQuote
    ) internal {
        self.feeGrowthBase = feeGrowthBase;
        self.feeGrowthQuote = feeGrowthQuote;
    }

    /// @notice update the liquidity info when after trade and save to storage
    /// @param self the liquidity info
    /// @param baseReserve the new value of baseReserve
    /// @param quoteReserve the new value of quoteReserve
    /// @param feeGrowth new growth value increase
    /// @param isBuy the side of trade
    function updateAMMReserve(
        Liquidity.Info storage self,
        uint128 quoteReserve,
        uint128 baseReserve,
        uint256 feeGrowth,
        bool isBuy
    ) internal {
        self.quoteReal = quoteReserve;
        self.baseReal = baseReserve;

        if (isBuy) {
            self.feeGrowthBase += feeGrowth;
        } else {
            self.feeGrowthQuote += feeGrowth;
        }
    }
}