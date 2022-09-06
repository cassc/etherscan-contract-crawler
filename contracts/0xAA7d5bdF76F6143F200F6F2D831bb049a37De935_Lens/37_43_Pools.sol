// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./math/TickMath.sol";
import "./math/SwapMath.sol";
import "./math/UnsafeMath.sol";
import "./math/Math.sol";
import "./Tiers.sol";
import "./Ticks.sol";
import "./TickMaps.sol";
import "./Positions.sol";
import "./Settlement.sol";

library Pools {
    using Math for uint96;
    using Math for uint128;
    using Tiers for Tiers.Tier;
    using Ticks for Ticks.Tick;
    using TickMaps for TickMaps.TickMap;
    using Positions for Positions.Position;

    error InvalidAmount();
    error InvalidTierChoices();
    error InvalidTick();
    error InvalidTickRangeForLimitOrder();
    error NoLiquidityForLimitOrder();
    error PositionAlreadySettled();
    error PositionNotSettled();

    uint24 internal constant MAX_SQRT_GAMMA = 100_000;
    uint96 internal constant BASE_LIQUIDITY_D8 = 100; // tier's base liquidity, scaled down 2^8. User pays it when adding a tier
    int256 internal constant SWAP_AMOUNT_TOLERANCE = 100; // tolerance between desired and actual swap amounts

    uint256 internal constant AMOUNT_DISTRIBUTION_BITS = 256 / MAX_TIERS; // i.e. 42 if MAX_TIERS is 6
    uint256 internal constant AMOUNT_DISTRIBUTION_RESOLUTION = AMOUNT_DISTRIBUTION_BITS - 1;

    /// @param unlocked     Reentrancy lock
    /// @param tickSpacing  Tick spacing. Only ticks that are multiples of the tick spacing can be used
    /// @param protocolFee  Protocol fee with base 255 (e.g. protocolFee = 51 for 20% protocol fee)
    /// @param tiers        Array of tiers
    /// @param tickMaps     Bitmap for each tier to store which ticks are initializated
    /// @param ticks        Mapping of tick states of each tier
    /// @param settlements  Mapping of settlements for token{0,1} singled-sided positions
    /// @param positions    Mapping of position states
    /// @param limitOrderTickSpacingMultipliers Tick spacing of limit order for each tier, as multiples of the pool's tick spacing
    struct Pool {
        bool unlocked;
        uint8 tickSpacing;
        uint8 protocolFee;
        Tiers.Tier[] tiers;
        mapping(uint256 => TickMaps.TickMap) tickMaps;
        mapping(uint256 => mapping(int24 => Ticks.Tick)) ticks;
        mapping(uint256 => mapping(int24 => Settlement.Info[2])) settlements;
        mapping(bytes32 => Positions.Position) positions;
        uint8[MAX_TIERS] limitOrderTickSpacingMultipliers;
    }

    function lock(Pool storage pool) internal {
        require(pool.unlocked);
        pool.unlocked = false;
    }

    function unlock(Pool storage pool) internal {
        pool.unlocked = true;
    }

    function getPoolAndId(
        mapping(bytes32 => Pool) storage pools,
        address token0,
        address token1
    ) internal view returns (Pool storage pool, bytes32 poolId) {
        poolId = keccak256(abi.encode(token0, token1));
        pool = pools[poolId];
    }

    /*===============================================================
     *                       INITIALIZATION
     *==============================================================*/

    function initialize(
        Pool storage pool,
        uint24 sqrtGamma,
        uint128 sqrtPrice,
        uint8 tickSpacing,
        uint8 protocolFee
    ) internal returns (uint256 amount0, uint256 amount1) {
        require(pool.tickSpacing == 0); // ensure not initialized
        require(TickMath.MIN_SQRT_P <= sqrtPrice && sqrtPrice <= TickMath.MAX_SQRT_P);
        require(tickSpacing > 0);

        pool.tickSpacing = tickSpacing;
        pool.protocolFee = protocolFee;

        (amount0, amount1) = _addTier(pool, sqrtGamma, sqrtPrice);

        // default enable limit order on first tier
        pool.limitOrderTickSpacingMultipliers[0] = 1;

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    function addTier(Pool storage pool, uint24 sqrtGamma)
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint8 tierId
        )
    {
        lock(pool);
        require((tierId = uint8(pool.tiers.length)) > 0);
        (amount0, amount1) = _addTier(pool, sqrtGamma, pool.tiers[0].sqrtPrice); // use 1st tier sqrt price as reference

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    function _addTier(
        Pool storage pool,
        uint24 sqrtGamma,
        uint128 sqrtPrice
    ) internal returns (uint256 amount0, uint256 amount1) {
        uint256 tierId = pool.tiers.length;
        require(tierId < MAX_TIERS);
        require(sqrtGamma <= MAX_SQRT_GAMMA);

        // initialize tier
        Tiers.Tier memory tier = Tiers.Tier({
            liquidity: uint128(BASE_LIQUIDITY_D8) << 8,
            sqrtPrice: sqrtPrice,
            sqrtGamma: sqrtGamma,
            tick: TickMath.sqrtPriceToTick(sqrtPrice),
            nextTickBelow: TickMath.MIN_TICK,
            nextTickAbove: TickMath.MAX_TICK,
            feeGrowthGlobal0: 0,
            feeGrowthGlobal1: 0
        });
        if (sqrtPrice == TickMath.MAX_SQRT_P) tier.tick--; // max tick is never crossed
        pool.tiers.push(tier);

        // initialize min tick & max tick
        Ticks.Tick storage lower = pool.ticks[tierId][TickMath.MIN_TICK];
        Ticks.Tick storage upper = pool.ticks[tierId][TickMath.MAX_TICK];
        (lower.liquidityLowerD8, lower.nextBelow, lower.nextAbove) = (
            BASE_LIQUIDITY_D8,
            TickMath.MIN_TICK,
            TickMath.MAX_TICK
        );
        (upper.liquidityUpperD8, upper.nextBelow, upper.nextAbove) = (
            BASE_LIQUIDITY_D8,
            TickMath.MIN_TICK,
            TickMath.MAX_TICK
        );

        // initialize tick map
        pool.tickMaps[tierId].set(TickMath.MIN_TICK);
        pool.tickMaps[tierId].set(TickMath.MAX_TICK);

        // calculate tokens to take for full-range base liquidity
        amount0 = UnsafeMath.ceilDiv(uint256(BASE_LIQUIDITY_D8) << (72 + 8), sqrtPrice);
        amount1 = UnsafeMath.ceilDiv(uint256(BASE_LIQUIDITY_D8) * sqrtPrice, 1 << (72 - 8));
    }

    /*===============================================================
     *                           SETTINGS
     *==============================================================*/

    function setPoolParameters(
        Pool storage pool,
        uint8 tickSpacing,
        uint8 protocolFee
    ) internal {
        require(pool.unlocked);
        require(tickSpacing > 0);
        pool.tickSpacing = tickSpacing;
        pool.protocolFee = protocolFee;
    }

    function setTierParameters(
        Pool storage pool,
        uint8 tierId,
        uint24 sqrtGamma,
        uint8 limitOrderTickSpacingMultiplier
    ) internal {
        require(pool.unlocked);
        require(tierId < pool.tiers.length);
        require(sqrtGamma <= MAX_SQRT_GAMMA);
        pool.tiers[tierId].sqrtGamma = sqrtGamma;
        pool.limitOrderTickSpacingMultipliers[tierId] = limitOrderTickSpacingMultiplier;
    }

    /*===============================================================
     *                            SWAP
     *==============================================================*/

    uint256 private constant Q64 = 0x10000000000000000;
    uint256 private constant Q128 = 0x100000000000000000000000000000000;

    /// @notice Emitted when limit order settlement occurs during a swap
    /// @dev Normally, we emit events from hub contract instead of from this pool library, but bubbling up the event
    /// data back to hub contract comsumes gas significantly, therefore we simply emit the "settle" event here.
    event Settle(
        bytes32 indexed poolId,
        uint8 indexed tierId,
        int24 indexed tickEnd,
        int24 tickStart,
        uint96 liquidityD8
    );

    struct SwapCache {
        bool zeroForOne;
        bool exactIn;
        uint8 protocolFee;
        uint256 protocolFeeAmt;
        uint256 tierChoices;
        TickMath.Cache tmCache;
        int256[MAX_TIERS] amounts;
        bytes32 poolId;
    }

    struct TierState {
        uint128 sqrtPTick;
        uint256 amountIn;
        uint256 amountOut;
        bool crossed;
    }

    /// @dev                    Struct returned by the "swap" function
    /// @param amount0          Pool's token0 balance change
    /// @param amount1          Pool's token1 balance change
    /// @param amountInDistribution Percentages of input amount routed to each tier (for logging)
    /// @param tierData         Array of tier's liquidity and sqrt price after the swap (for logging)
    /// @param protocolFeeAmt   Amount of input token as protocol fee
    struct SwapResult {
        int256 amount0;
        int256 amount1;
        uint256 amountInDistribution;
        uint256 amountOutDistribution;
        uint256[] tierData;
        uint256 protocolFeeAmt;
    }

    /// @notice                 Perform a swap in the pool
    /// @param pool             Pool storage pointer
    /// @param isToken0         True if amtDesired refers to token0
    /// @param amtDesired       Desired swap amount (positive: exact input, negative: exact output)
    /// @param tierChoices      Bitmap to allow which tiers to swap
    /// @param poolId           Pool id, only used for emitting settle event. Can pass in zero to skip emitting event
    /// @return result          Swap result
    function swap(
        Pool storage pool,
        bool isToken0,
        int256 amtDesired,
        uint256 tierChoices,
        bytes32 poolId // only used for `Settle` event
    ) internal returns (SwapResult memory result) {
        lock(pool);
        Tiers.Tier[] memory tiers;
        TierState[MAX_TIERS] memory states;
        unchecked {
            // truncate tierChoices
            uint256 tiersCount = pool.tiers.length;
            uint256 maxTierChoices = (1 << tiersCount) - 1;
            tierChoices &= maxTierChoices;

            if (amtDesired == 0 || amtDesired == SwapMath.REJECTED) revert InvalidAmount();
            if (tierChoices == 0) revert InvalidTierChoices();

            // only load tiers that are allowed by users
            if (tierChoices == maxTierChoices) {
                tiers = pool.tiers;
            } else {
                tiers = new Tiers.Tier[](tiersCount);
                for (uint256 i; i < tiers.length; i++) {
                    if (tierChoices & (1 << i) != 0) tiers[i] = pool.tiers[i];
                }
            }
        }

        SwapCache memory cache = SwapCache({
            zeroForOne: isToken0 == (amtDesired > 0),
            exactIn: amtDesired > 0,
            protocolFee: pool.protocolFee,
            protocolFeeAmt: 0,
            tierChoices: tierChoices,
            tmCache: TickMath.Cache({tick: type(int24).max, sqrtP: 0}),
            amounts: _emptyInt256Array(),
            poolId: poolId
        });

        int256 initialAmtDesired = amtDesired;
        int256 amountA; // pool's balance change of the token which "amtDesired" refers to
        int256 amountB; // pool's balance change of the opposite token

        while (true) {
            // calculate the swap amount for each tier
            cache.amounts = cache.exactIn
                ? SwapMath.calcTierAmtsIn(tiers, isToken0, amtDesired, cache.tierChoices)
                : SwapMath.calcTierAmtsOut(tiers, isToken0, amtDesired, cache.tierChoices);

            // compute the swap for each tier
            for (uint256 i; i < tiers.length; ) {
                (int256 amtAStep, int256 amtBStep) = _swapStep(pool, isToken0, cache, states[i], tiers[i], i);
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
                    (cache.exactIn ? amtDesired <= SWAP_AMOUNT_TOLERANCE : amtDesired >= -SWAP_AMOUNT_TOLERANCE) ||
                    cache.tierChoices == 0
                ) break;
            }
        }

        result.protocolFeeAmt = cache.protocolFeeAmt;
        unchecked {
            (result.amountInDistribution, result.amountOutDistribution, result.tierData) = _updateTiers(
                pool,
                states,
                tiers,
                uint256(cache.exactIn ? amountA : amountB),
                uint256(cache.exactIn ? -amountB : -amountA)
            );
        }
        (result.amount0, result.amount1) = isToken0 ? (amountA, amountB) : (amountB, amountA);

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    function _swapStep(
        Pool storage pool,
        bool isToken0,
        SwapCache memory cache,
        TierState memory state,
        Tiers.Tier memory tier,
        uint256 tierId
    ) internal returns (int256 amtAStep, int256 amtBStep) {
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

            // cache input & output amounts for later event logging (locally)
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
            Ticks.Tick storage cross = pool.ticks[tierId][tickCross];
            cross.flip(tier.feeGrowthGlobal0, tier.feeGrowthGlobal1);
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

            // settle single-sided positions (i.e. filled limit orders) if neccessary
            if (cache.zeroForOne ? cross.needSettle0 : cross.needSettle1) {
                (int24 tickStart, uint96 liquidityD8Settled) = Settlement.settle(
                    pool.settlements[tierId],
                    pool.ticks[tierId],
                    pool.tickMaps[tierId],
                    tier,
                    tickCross,
                    cache.zeroForOne
                );
                if (cache.poolId != 0) {
                    emit Settle(cache.poolId, uint8(tierId), tickCross, tickStart, liquidityD8Settled);
                }
            }
        }
    }

    /// @dev Apply the post-swap data changes from memory to storage, also prepare data for event logging
    function _updateTiers(
        Pool storage pool,
        TierState[MAX_TIERS] memory states,
        Tiers.Tier[] memory tiers,
        uint256 amtIn,
        uint256 amtOut
    )
        internal
        returns (
            uint256 amtInDistribution,
            uint256 amtOutDistribution,
            uint256[] memory tierData
        )
    {
        tierData = new uint256[](tiers.length);
        unchecked {
            bool amtInNoOverflow = amtIn < (1 << (256 - AMOUNT_DISTRIBUTION_RESOLUTION));
            bool amtOutNoOverflow = amtOut < (1 << (256 - AMOUNT_DISTRIBUTION_RESOLUTION));

            for (uint256 i; i < tiers.length; i++) {
                TierState memory state = states[i];
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

                    pool.tiers[i] = tier;

                    // prepare data for logging
                    tierData[i] = (uint256(tier.sqrtPrice) << 128) | tier.liquidity;
                    if (amtIn > 0) {
                        amtInDistribution |= (
                            amtInNoOverflow
                                ? (state.amountIn << AMOUNT_DISTRIBUTION_RESOLUTION) / amtIn
                                : state.amountIn / ((amtIn >> AMOUNT_DISTRIBUTION_RESOLUTION) + 1)
                        ) << (i * AMOUNT_DISTRIBUTION_BITS); // prettier-ignore
                    }
                    if (amtOut > 0) {
                        amtOutDistribution |= (
                            amtOutNoOverflow
                                ? (state.amountOut << AMOUNT_DISTRIBUTION_RESOLUTION) / amtOut
                                : state.amountOut / ((amtOut >> AMOUNT_DISTRIBUTION_RESOLUTION) + 1)
                        ) << (i * AMOUNT_DISTRIBUTION_BITS); // prettier-ignore
                    }
                }
            }
        }
    }

    function _emptyInt256Array() internal pure returns (int256[MAX_TIERS] memory) {}

    /*===============================================================
     *                      UPDATE LIQUIDITY
     *==============================================================*/

    function _checkTickInputs(int24 tickLower, int24 tickUpper) internal pure {
        if (tickLower >= tickUpper || TickMath.MIN_TICK > tickLower || tickUpper > TickMath.MAX_TICK) {
            revert InvalidTick();
        }
    }

    /// @notice                 Update a position's liquidity
    /// @param owner            Address of the position owner
    /// @param positionRefId    Reference id of the position
    /// @param tierId           Tier index of the position
    /// @param tickLower        Lower tick boundary of the position
    /// @param tickUpper        Upper tick boundary of the position
    /// @param liquidityDeltaD8 Amount of liquidity change, divided by 2^8
    /// @param collectAllFees   True to collect all remaining accrued fees of the position
    function updateLiquidity(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        int96 liquidityDeltaD8,
        bool collectAllFees
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmtOut0,
            uint256 feeAmtOut1
        )
    {
        lock(pool);
        _checkTickInputs(tickLower, tickUpper);
        if (liquidityDeltaD8 > 0) {
            if (tickLower % int24(uint24(pool.tickSpacing)) != 0) revert InvalidTick();
            if (tickUpper % int24(uint24(pool.tickSpacing)) != 0) revert InvalidTick();
        }
        // -------------------- UPDATE LIQUIDITY --------------------
        {
            // update current liquidity if in-range
            Tiers.Tier storage tier = pool.tiers[tierId];
            if (tickLower <= tier.tick && tier.tick < tickUpper)
                tier.liquidity = tier.liquidity.addInt128(int128(liquidityDeltaD8) << 8);
        }
        // --------------------- UPDATE TICKS -----------------------
        {
            bool initialized;
            initialized = _updateTick(pool, tierId, tickLower, liquidityDeltaD8, true);
            initialized = _updateTick(pool, tierId, tickUpper, liquidityDeltaD8, false) || initialized;
            if (initialized) {
                Tiers.Tier storage tier = pool.tiers[tierId];
                tier.updateNextTick(tickLower);
                tier.updateNextTick(tickUpper);
            }
        }
        // -------------------- UPDATE POSITION ---------------------
        (feeAmtOut0, feeAmtOut1) = _updatePosition(
            pool,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper,
            liquidityDeltaD8,
            collectAllFees
        );
        // -------------------- CLEAN UP TICKS ----------------------
        if (liquidityDeltaD8 < 0) {
            bool deleted;
            deleted = _deleteEmptyTick(pool, tierId, tickLower);
            deleted = _deleteEmptyTick(pool, tierId, tickUpper) || deleted;

            // reset tier's next ticks if any ticks deleted
            if (deleted) {
                Tiers.Tier storage tier = pool.tiers[tierId];
                int24 below = TickMaps.nextBelow(pool.tickMaps[tierId], tier.tick + 1);
                int24 above = pool.ticks[tierId][below].nextAbove;
                tier.nextTickBelow = below;
                tier.nextTickAbove = above;
            }
        }
        // -------------------- TOKEN AMOUNTS -----------------------
        // calculate input and output amount for the liquidity change
        if (liquidityDeltaD8 != 0)
            (amount0, amount1) = PoolMath.calcAmtsForLiquidity(
                pool.tiers[tierId].sqrtPrice,
                TickMath.tickToSqrtPrice(tickLower),
                TickMath.tickToSqrtPrice(tickUpper),
                liquidityDeltaD8
            );

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    /*===============================================================
     *                    TICKS (UPDATE LIQUIDITY)
     *==============================================================*/

    function _updateTick(
        Pool storage pool,
        uint8 tierId,
        int24 tick,
        int96 liquidityDeltaD8,
        bool isLower
    ) internal returns (bool initialized) {
        mapping(int24 => Ticks.Tick) storage ticks = pool.ticks[tierId];
        Ticks.Tick storage obj = ticks[tick];

        if (obj.liquidityLowerD8 == 0 && obj.liquidityUpperD8 == 0) {
            // initialize tick if adding liquidity to empty tick
            if (liquidityDeltaD8 > 0) {
                TickMaps.TickMap storage tickMap = pool.tickMaps[tierId];
                int24 below = tickMap.nextBelow(tick);
                int24 above = ticks[below].nextAbove;
                obj.nextBelow = below;
                obj.nextAbove = above;
                ticks[below].nextAbove = tick;
                ticks[above].nextBelow = tick;

                tickMap.set(tick);
                initialized = true;
            }

            // assume past fees and reward were generated _below_ the current tick
            Tiers.Tier storage tier = pool.tiers[tierId];
            if (tick <= tier.tick) {
                obj.feeGrowthOutside0 = tier.feeGrowthGlobal0;
                obj.feeGrowthOutside1 = tier.feeGrowthGlobal1;
            }
        }

        // update liquidity
        if (isLower) {
            obj.liquidityLowerD8 = obj.liquidityLowerD8.addInt96(liquidityDeltaD8);
        } else {
            obj.liquidityUpperD8 = obj.liquidityUpperD8.addInt96(liquidityDeltaD8);
        }
    }

    function _deleteEmptyTick(
        Pool storage pool,
        uint8 tierId,
        int24 tick
    ) internal returns (bool deleted) {
        mapping(int24 => Ticks.Tick) storage ticks = pool.ticks[tierId];
        Ticks.Tick storage obj = ticks[tick];

        if (obj.liquidityLowerD8 == 0 && obj.liquidityUpperD8 == 0) {
            assert(tick != TickMath.MIN_TICK && tick != TickMath.MAX_TICK);
            int24 below = obj.nextBelow;
            int24 above = obj.nextAbove;
            ticks[below].nextAbove = above;
            ticks[above].nextBelow = below;
            delete ticks[tick];
            pool.tickMaps[tierId].unset(tick);
            deleted = true;
        }
    }

    /*===============================================================
     *                   POSITION (UPDATE LIQUIDITY)
     *==============================================================*/

    function _getFeeGrowthInside(
        Pool storage pool,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint80 feeGrowthInside0, uint80 feeGrowthInside1) {
        Ticks.Tick storage upper = pool.ticks[tierId][tickUpper];
        Ticks.Tick storage lower = pool.ticks[tierId][tickLower];
        Tiers.Tier storage tier = pool.tiers[tierId];
        int24 tickCurrent = tier.tick;

        unchecked {
            if (tickCurrent < tickLower) {
                // current price below range
                feeGrowthInside0 = lower.feeGrowthOutside0 - upper.feeGrowthOutside0;
                feeGrowthInside1 = lower.feeGrowthOutside1 - upper.feeGrowthOutside1;
            } else if (tickCurrent >= tickUpper) {
                // current price above range
                feeGrowthInside0 = upper.feeGrowthOutside0 - lower.feeGrowthOutside0;
                feeGrowthInside1 = upper.feeGrowthOutside1 - lower.feeGrowthOutside1;
            } else {
                // current price in range
                feeGrowthInside0 = tier.feeGrowthGlobal0 - upper.feeGrowthOutside0 - lower.feeGrowthOutside0;
                feeGrowthInside1 = tier.feeGrowthGlobal1 - upper.feeGrowthOutside1 - lower.feeGrowthOutside1;
            }
        }
    }

    function _updatePosition(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        int96 liquidityDeltaD8,
        bool collectAllFees
    ) internal returns (uint256 feeAmtOut0, uint256 feeAmtOut1) {
        Positions.Position storage position = Positions.get(
            pool.positions,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper
        );
        {
            // update position liquidity and accrue fees
            (uint80 feeGrowth0, uint80 feeGrowth1) = _getFeeGrowthInside(pool, tierId, tickLower, tickUpper);
            (feeAmtOut0, feeAmtOut1) = position.update(liquidityDeltaD8, feeGrowth0, feeGrowth1, collectAllFees);
        }

        // update settlement if position is an unsettled limit order
        if (position.limitOrderType != Positions.NOT_LIMIT_ORDER) {
            // passing a zero default tick spacing to here since the settlement state must be already initialized as
            // this position has been a limit order
            uint32 nextSnapshotId = Settlement.update(
                pool.settlements[tierId],
                pool.ticks[tierId],
                tickLower,
                tickUpper,
                position.limitOrderType,
                liquidityDeltaD8,
                0
            );

            // not allowed to update if already settled
            if (position.settlementSnapshotId != nextSnapshotId) revert PositionAlreadySettled();

            // reset position to normal if it is emptied
            if (position.liquidityD8 == 0) {
                position.limitOrderType = Positions.NOT_LIMIT_ORDER;
                position.settlementSnapshotId = 0;
            }
        }
    }

    /*===============================================================
     *                          LIMIT ORDER
     *==============================================================*/

    /// @notice Set (or unset) position to (or from) a limit order
    /// @dev It first unsets position from being a limit order (if it is), then set position to a new limit order type
    function setLimitOrderType(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint8 limitOrderType
    ) internal {
        require(pool.unlocked);
        require(limitOrderType <= Positions.ONE_FOR_ZERO);
        _checkTickInputs(tickLower, tickUpper);

        Positions.Position storage position = Positions.get(
            pool.positions,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper
        );
        uint16 defaultTickSpacing = uint16(pool.tickSpacing) * pool.limitOrderTickSpacingMultipliers[tierId];

        // unset position to normal type
        if (position.limitOrderType != Positions.NOT_LIMIT_ORDER) {
            (uint32 nextSnapshotId, ) = Settlement.update(
                pool.settlements[tierId],
                pool.ticks[tierId],
                tickLower,
                tickUpper,
                position.limitOrderType,
                position.liquidityD8,
                false,
                defaultTickSpacing
            );

            // not allowed to update if already settled
            if (position.settlementSnapshotId != nextSnapshotId) revert PositionAlreadySettled();

            // unset to normal
            position.limitOrderType = Positions.NOT_LIMIT_ORDER;
            position.settlementSnapshotId = 0;
        }

        // set position to limit order
        if (limitOrderType != Positions.NOT_LIMIT_ORDER) {
            if (position.liquidityD8 == 0) revert NoLiquidityForLimitOrder();
            (uint32 nextSnapshotId, uint16 tickSpacing) = Settlement.update(
                pool.settlements[tierId],
                pool.ticks[tierId],
                tickLower,
                tickUpper,
                limitOrderType,
                position.liquidityD8,
                true,
                defaultTickSpacing
            );

            // ensure position has a correct tick range for limit order
            if (uint24(tickUpper - tickLower) != tickSpacing) revert InvalidTickRangeForLimitOrder();

            // set to limit order
            position.limitOrderType = limitOrderType;
            position.settlementSnapshotId = nextSnapshotId;
        }
    }

    /// @notice Collect tokens from a settled position. Reset to normal position if all tokens are collected
    /// @dev We only need to update position state. No need to remove any active liquidity from tier or update upper or
    /// lower tick states as these have already been done when settling these positions during a swap
    function collectSettled(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper,
        uint96 liquidityD8,
        bool collectAllFees
    )
        internal
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 feeAmtOut0,
            uint256 feeAmtOut1
        )
    {
        lock(pool);
        _checkTickInputs(tickLower, tickUpper);

        Positions.Position storage position = Positions.get(
            pool.positions,
            owner,
            positionRefId,
            tierId,
            tickLower,
            tickUpper
        );

        {
            // ensure it's a settled limit order, and get data snapshot
            (bool settled, Settlement.Snapshot memory snapshot) = Settlement.getSnapshot(
                pool.settlements[tierId],
                position,
                tickLower,
                tickUpper
            );
            if (!settled) revert PositionNotSettled();

            // update position using snapshotted data
            (feeAmtOut0, feeAmtOut1) = position.update(
                -liquidityD8.toInt96(),
                snapshot.feeGrowthInside0,
                snapshot.feeGrowthInside1,
                collectAllFees
            );
        }

        // calculate output amounts using the price where settlement was done
        uint128 sqrtPriceLower = TickMath.tickToSqrtPrice(tickLower);
        uint128 sqrtPriceUpper = TickMath.tickToSqrtPrice(tickUpper);
        (amount0, amount1) = PoolMath.calcAmtsForLiquidity(
            position.limitOrderType == Positions.ZERO_FOR_ONE ? sqrtPriceUpper : sqrtPriceLower,
            sqrtPriceLower,
            sqrtPriceUpper,
            -liquidityD8.toInt96()
        );

        // reset position to normal if it is emptied
        if (position.liquidityD8 == 0) {
            position.limitOrderType = Positions.NOT_LIMIT_ORDER;
            position.settlementSnapshotId = 0;
        }

        // BE AWARE the pool is locked. Please unlock it after token transfer is done.
    }

    /*===============================================================
     *                        VIEW FUNCTIONS
     *==============================================================*/

    function getPositionFeeGrowthInside(
        Pool storage pool,
        address owner,
        uint256 positionRefId,
        uint8 tierId,
        int24 tickLower,
        int24 tickUpper
    ) internal view returns (uint80 feeGrowthInside0, uint80 feeGrowthInside1) {
        if (owner != address(0)) {
            (bool settled, Settlement.Snapshot memory snapshot) = Settlement.getSnapshot(
                pool.settlements[tierId],
                Positions.get(pool.positions, owner, positionRefId, tierId, tickLower, tickUpper),
                tickLower,
                tickUpper
            );
            if (settled) return (snapshot.feeGrowthInside0, snapshot.feeGrowthInside1);
        }
        return _getFeeGrowthInside(pool, tierId, tickLower, tickUpper);
    }

    /// @dev Convert fixed-sized array to dynamic-sized
    function getLimitOrderTickSpacingMultipliers(Pool storage pool) internal view returns (uint8[] memory multipliers) {
        uint8[MAX_TIERS] memory ms = pool.limitOrderTickSpacingMultipliers;
        multipliers = new uint8[](pool.tiers.length);
        unchecked {
            for (uint256 i; i < multipliers.length; i++) multipliers[i] = ms[i];
        }
    }
}