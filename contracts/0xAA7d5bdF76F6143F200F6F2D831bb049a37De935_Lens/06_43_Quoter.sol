// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.10;

import "../../interfaces/lens/IQuoter.sol";
import "../../libraries/utils/PathLib.sol";
import "../../libraries/Pools.sol";
import "../../MuffinHub.sol";
import "./LensBase.sol";

/**
 * @dev There's two quoting methods available in this contract.
 * 1. Call "swap" in Hub contract, then throw an error to revert the swap.
 * 2. Fetch data from hub and simulate the swap in this contract.
 *
 * The former guarantees correctness and can estimate the gas cost of the swap.
 * The latter can generate a more detailed result, e.g. the input and output amounts for each tier.
 */
abstract contract Quoter is IQuoter, LensBase {
    using PathLib for bytes;

    /*===============================================================
     *                  QUOTE BY POPULATING ERROR
     *==============================================================*/

    function muffinSwapCallback(
        address,
        address,
        uint256 amountIn,
        uint256 amountOut,
        bytes calldata
    ) external pure {
        assembly {
            let ptr := mload(0x40) // free memory pointer
            mstore(add(ptr, 0), amountIn)
            mstore(add(ptr, 32), amountOut)
            revert(ptr, 64)
        }
    }

    function _parseRevertReason(bytes memory reason) internal pure returns (uint256 amountIn, uint256 amountOut) {
        if (reason.length == 64) return abi.decode(reason, (uint256, uint256));
        assembly {
            revert(add(32, reason), mload(reason))
        }
    }

    /// @inheritdoc IQuoter
    function quoteSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    )
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        )
    {
        uint256 gasBefore = gasleft();
        try hub.swap(tokenIn, tokenOut, tierChoices, amountDesired, address(this), 0, 0, new bytes(0)) {} catch (
            bytes memory reason
        ) {
            gasUsed = gasBefore - gasleft();
            (amountIn, amountOut) = _parseRevertReason(reason);
        }
    }

    /// @inheritdoc IQuoter
    function quote(bytes calldata path, int256 amountDesired)
        external
        returns (
            uint256 amountIn,
            uint256 amountOut,
            uint256 gasUsed
        )
    {
        uint256 gasBefore = gasleft();
        try
            hub.swapMultiHop(
                IMuffinHubActions.SwapMultiHopParams({
                    path: path,
                    amountDesired: amountDesired,
                    recipient: address(this),
                    recipientAccRefId: 0,
                    senderAccRefId: 0,
                    data: new bytes(0)
                })
            )
        {} catch (bytes memory reason) {
            gasUsed = gasBefore - gasleft();
            (amountIn, amountOut) = _parseRevertReason(reason);
        }
    }

    /*===============================================================
     *                   QUOTE BY SIMULATING SWAP
     *==============================================================*/

    // Hop struct, defined in IQuoter.sol.
    // ```
    // struct Hop {
    //     uint256 amountIn;
    //     uint256 amountOut;
    //     uint256 protocolFeeAmt;
    //     uint256[] tierAmountsIn;
    //     uint256[] tierAmountsOut;
    //     uint256[] tierData;
    // }
    // ```

    /// @inheritdoc IQuoter
    function simulateSingle(
        address tokenIn,
        address tokenOut,
        uint256 tierChoices,
        int256 amountDesired
    ) external view returns (Hop memory hop) {
        bytes32 poolId = tokenIn < tokenOut
            ? keccak256(abi.encode(tokenIn, tokenOut))
            : keccak256(abi.encode(tokenOut, tokenIn));
        return _swap(poolId, (amountDesired > 0) == (tokenIn < tokenOut), amountDesired, tierChoices);
    }

    /// @inheritdoc IQuoter
    function simulate(bytes calldata path, int256 amountDesired)
        external
        view
        returns (
            uint256 amountIn,
            uint256 amountOut,
            Hop[] memory hops
        )
    {
        if (path.invalid()) revert MuffinHub.InvalidSwapPath();

        bool exactIn = amountDesired > 0;
        bytes32[] memory poolIds = new bytes32[](path.hopCount());
        hops = new Hop[](poolIds.length);

        unchecked {
            int256 amtDesired = amountDesired;
            for (uint256 i; i < poolIds.length; i++) {
                (address tokenIn, address tokenOut, uint256 tierChoices) = path.decodePool(i, exactIn);

                poolIds[i] = tokenIn < tokenOut
                    ? keccak256(abi.encode(tokenIn, tokenOut))
                    : keccak256(abi.encode(tokenOut, tokenIn));

                // For an "exact output" swap, it's possible to not receive the full desired output amount. therefore, in
                // the 2nd (and following) swaps, we request more token output so as to ensure we get enough tokens to pay
                // for the previous swa The extra token is not refunded and thus results in a very small extra cost.
                hops[i] = _swap(
                    poolIds[i],
                    (amtDesired > 0) == (tokenIn < tokenOut),
                    (exactIn || i == 0) ? amtDesired : amtDesired - Pools.SWAP_AMOUNT_TOLERANCE,
                    tierChoices
                );
                (uint256 amtIn, uint256 amtOut) = (hops[i].amountIn, hops[i].amountOut);

                if (exactIn) {
                    if (i == 0) amountIn = amtIn;
                    amtDesired = int256(amtOut);
                } else {
                    if (i == 0) amountOut = amtOut;
                    else if (amtOut < uint256(-amtDesired)) revert MuffinHub.NotEnoughIntermediateOutput();
                    amtDesired = -int256(amtIn);
                }
            }
            if (exactIn) {
                amountOut = uint256(amtDesired);
            } else {
                amountIn = uint256(-amtDesired);
            }
        }
        // emulate pool locks
        require(!QuickSort.sortAndHasDuplicate(poolIds), "POOL_REPEATED");
    }

    function _swap(
        bytes32 poolId,
        bool isToken0,
        int256 amtDesired,
        uint256 tierChoices
    ) internal view returns (Hop memory hop) {
        Tiers.Tier[] memory tiers;
        Pools.TierState[MAX_TIERS] memory states;

        unchecked {
            uint256 tiersCount = hub.getTiersCount(poolId);
            uint256 maxTierChoices = (1 << tiersCount) - 1;
            tierChoices &= maxTierChoices;

            if (amtDesired == 0 || amtDesired == SwapMath.REJECTED) revert Pools.InvalidAmount();
            if (tierChoices == 0) revert Pools.InvalidTierChoices();

            // only load tiers that are allowed by users
            if (tierChoices == maxTierChoices) {
                tiers = hub.getAllTiers(poolId);
            } else {
                tiers = new Tiers.Tier[](tiersCount);
                for (uint256 i; i < tiers.length; i++) {
                    if (tierChoices & (1 << i) != 0) tiers[i] = hub.getTier(poolId, uint8(i));
                }
            }
        }

        Pools.SwapCache memory cache = Pools.SwapCache({
            zeroForOne: isToken0 == (amtDesired > 0),
            exactIn: amtDesired > 0,
            protocolFee: 0,
            protocolFeeAmt: 0,
            tierChoices: tierChoices & ((1 << tiers.length) - 1),
            tmCache: TickMath.Cache({tick: type(int24).max, sqrtP: 0}),
            amounts: Pools._emptyInt256Array(),
            poolId: 0
        });
        (, cache.protocolFee) = hub.getPoolParameters(poolId);

        int256 initialAmtDesired = amtDesired;
        int256 amountA; // pool's balance change of the token which "amtDesired" refers to
        int256 amountB; // pool's balance change of the opposite token

        while (true) {
            // calculate the swap amount for each tier
            cache.amounts = amtDesired > 0
                ? SwapMath.calcTierAmtsIn(tiers, isToken0, amtDesired, tierChoices)
                : SwapMath.calcTierAmtsOut(tiers, isToken0, amtDesired, tierChoices);

            // compute the swap for each tier
            for (uint256 i; i < tiers.length; ) {
                (int256 amtAStep, int256 amtBStep) = _swapStep(poolId, isToken0, cache, states[i], tiers[i], i);
                amountA += amtAStep;
                amountB += amtBStep;
                unchecked {
                    i++;
                }
            }

            // check if we meet the stopping criteria
            amtDesired = initialAmtDesired - amountA;
            unchecked {
                if (
                    (cache.exactIn ? amtDesired <= Pools.SWAP_AMOUNT_TOLERANCE : amtDesired >= -Pools.SWAP_AMOUNT_TOLERANCE) ||
                    cache.tierChoices == 0
                ) break; // prettier-ignore
            }
        }

        hop.protocolFeeAmt = cache.protocolFeeAmt;
        (hop.tierAmountsIn, hop.tierAmountsOut, hop.tierData) = _computeTicksAndRelevantData(states, tiers);
        (hop.amountIn, hop.amountOut) = cache.exactIn
            ? (uint256(amountA), uint256(-amountB))
            : (uint256(amountB), uint256(-amountA));
    }

    function _swapStep(
        bytes32 poolId,
        bool isToken0,
        Pools.SwapCache memory cache,
        Pools.TierState memory state,
        Tiers.Tier memory tier,
        uint256 tierId
    ) internal view returns (int256 amtAStep, int256 amtBStep) {
        if (cache.amounts[tierId] == SwapMath.REJECTED) return (0, 0);

        // calculate sqrt price of the next tick
        if (state.sqrtPTick == 0)
            state.sqrtPTick = TickMath.tickToSqrtPriceMemoized(
                cache.tmCache,
                cache.zeroForOne ? tier.nextTickBelow : tier.nextTickAbove
            );

        unchecked {
            // calculate input & output amts, new sqrt price, and fee amt for this swap step
            uint256 feeAmtStep;
            (amtAStep, amtBStep, tier.sqrtPrice, feeAmtStep) = SwapMath.computeStep(
                isToken0,
                cache.exactIn,
                cache.amounts[tierId],
                tier.sqrtPrice,
                state.sqrtPTick,
                tier.liquidity,
                tier.sqrtGamma
            );
            if (amtAStep == SwapMath.REJECTED) return (0, 0);

            // cache input amount for later event logging (locally)
            if (cache.exactIn) {
                state.amountIn += uint256(amtAStep);
                state.amountOut += uint256(-amtBStep);
            } else {
                state.amountIn += uint256(amtBStep);
                state.amountOut += uint256(-amtAStep);
            }

            // update protocol fee amt (locally)
            uint256 protocolFeeAmt = (feeAmtStep * cache.protocolFee) / type(uint8).max;
            cache.protocolFeeAmt += protocolFeeAmt;
            feeAmtStep -= protocolFeeAmt;

            // update fee growth (locally) (realistically assume feeAmtStep < 2**192)
            uint80 feeGrowth = uint80((feeAmtStep << 64) / tier.liquidity);
            if (cache.zeroForOne) {
                tier.feeGrowthGlobal0 += feeGrowth;
            } else {
                tier.feeGrowthGlobal1 += feeGrowth;
            }
        }

        // handle cross tick, which updates a tick state
        if (tier.sqrtPrice == state.sqrtPTick) {
            int24 tickCross = cache.zeroForOne ? tier.nextTickBelow : tier.nextTickAbove;

            // skip crossing tick if reaches the end of the supported price range
            if (tickCross == TickMath.MIN_TICK || tickCross == TickMath.MAX_TICK) {
                cache.tierChoices &= ~(1 << tierId);
                return (amtAStep, amtBStep);
            }

            // clear cached tick price, so as to calculate a new one in next loop
            state.sqrtPTick = 0;
            state.crossed = true;

            // flip the direction of tick's data (effect)
            Ticks.Tick memory cross = hub.getTick(poolId, uint8(tierId), tickCross);
            // cross.flip(tier.feeGrowthGlobal0, tier.feeGrowthGlobal1, pool.secondsPerLiquidityCumulative);
            unchecked {
                // update tier's liquidity and next ticks (locally)
                (uint128 liqLowerD8, uint128 liqUpperD8) = (cross.liquidityLowerD8, cross.liquidityUpperD8);
                if (cache.zeroForOne) {
                    tier.liquidity = tier.liquidity + (liqUpperD8 << 8) - (liqLowerD8 << 8);
                    tier.nextTickBelow = cross.nextBelow;
                    tier.nextTickAbove = tickCross;
                } else {
                    tier.liquidity = tier.liquidity + (liqLowerD8 << 8) - (liqUpperD8 << 8);
                    tier.nextTickBelow = tickCross;
                    tier.nextTickAbove = cross.nextAbove;
                }
            }

            // // settle single-sided positions (i.e. filled limit orders) if neccessary
            // if (cache.zeroForOne ? cross.needSettle0 : cross.needSettle1)
            //     Settlement.settle(
            //         pool.settlements[tierId],
            //         pool.ticks[tierId],
            //         pool.tickMaps[tierId],
            //         tier,
            //         tickCross,
            //         cache.zeroForOne
            //     );
        }
    }

    function _computeTicksAndRelevantData(Pools.TierState[MAX_TIERS] memory states, Tiers.Tier[] memory tiers)
        internal
        pure
        returns (
            uint256[] memory tierAmountsIn,
            uint256[] memory tierAmountsOut,
            uint256[] memory tierData
        )
    {
        tierData = new uint256[](tiers.length);
        tierAmountsIn = new uint256[](tiers.length);
        tierAmountsOut = new uint256[](tiers.length);
        unchecked {
            for (uint8 i; i < tiers.length; i++) {
                Pools.TierState memory state = states[i];
                // we can safely assume tier data is unchanged when there's zero input amount and no crossing tick,
                // since we would have rejected the tier if such case happened.
                if (state.amountIn > 0 || state.crossed) {
                    Tiers.Tier memory tier = tiers[i];
                    // calculate current tick:
                    // if tier's price is equal to tick's price (let say the tick is T), the tier is expected to be in
                    // the upper tick space [T, T+1]. Only if the tier's next upper crossing tick is T, the tier is in
                    // the lower tick space [T-1, T].
                    tier.tick = TickMath.sqrtPriceToTick(tier.sqrtPrice);
                    if (tier.tick == tier.nextTickAbove) tier.tick--;

                    // pool.tiers[i] = tier;

                    // prepare data for logging
                    tierData[i] = (uint256(tier.sqrtPrice) << 128) | tier.liquidity;
                    tierAmountsIn[i] = state.amountIn;
                    tierAmountsOut[i] = state.amountOut;
                }
            }
        }
    }
}

/// @dev https://gist.github.com/subhodi/b3b86cc13ad2636420963e692a4d896f
library QuickSort {
    function sortAndHasDuplicate(bytes32[] memory data) internal pure returns (bool) {
        unchecked {
            sort(data);
            for (uint256 i = 1; i < data.length; i++) if (data[i - 1] == data[i]) return true;
            return false;
        }
    }

    function sort(bytes32[] memory data) internal pure {
        unchecked {
            require(data.length > 0);
            require(data.length <= uint256(type(int256).max));
            _quickSort(data, int256(0), int256(data.length - 1));
        }
    }

    function _quickSort(
        bytes32[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        unchecked {
            int256 i = left;
            int256 j = right;
            if (i == j) return;
            bytes32 pivot = arr[uint256(left + (right - left) / 2)];
            while (i <= j) {
                while (arr[uint256(i)] < pivot) i++;
                while (pivot < arr[uint256(j)]) j--;
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
                    i++;
                    j--;
                }
            }
            if (left < j) _quickSort(arr, left, j);
            if (i < right) _quickSort(arr, i, right);
        }
    }
}