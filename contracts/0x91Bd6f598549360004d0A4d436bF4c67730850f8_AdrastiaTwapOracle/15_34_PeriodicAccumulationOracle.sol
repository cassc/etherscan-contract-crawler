//SPDX-License-Identifier: MIT
pragma solidity =0.8.13;

import "@openzeppelin-v4/contracts/utils/math/SafeCast.sol";
import "@openzeppelin-v4/contracts/utils/math/Math.sol";

import "./PeriodicOracle.sol";
import "../interfaces/ILiquidityAccumulator.sol";
import "../interfaces/IHasLiquidityAccumulator.sol";
import "../interfaces/IPriceAccumulator.sol";
import "../interfaces/IHasPriceAccumulator.sol";

import "../libraries/AccumulationLibrary.sol";
import "../libraries/ObservationLibrary.sol";

contract PeriodicAccumulationOracle is PeriodicOracle, IHasLiquidityAccumulator, IHasPriceAccumulator {
    using SafeCast for uint256;

    address public immutable override liquidityAccumulator;
    address public immutable override priceAccumulator;

    mapping(address => AccumulationLibrary.PriceAccumulator) public priceAccumulations;
    mapping(address => AccumulationLibrary.LiquidityAccumulator) public liquidityAccumulations;

    constructor(
        address liquidityAccumulator_,
        address priceAccumulator_,
        address quoteToken_,
        uint256 period_
    ) PeriodicOracle(quoteToken_, period_) {
        liquidityAccumulator = liquidityAccumulator_;
        priceAccumulator = priceAccumulator_;
    }

    /// @inheritdoc PeriodicOracle
    function canUpdate(bytes memory data) public view virtual override returns (bool) {
        if (
            (IUpdateable(priceAccumulator).needsUpdate(data) &&
                IUpdateable(priceAccumulator).timeSinceLastUpdate(data) >= period) ||
            (IUpdateable(liquidityAccumulator).needsUpdate(data) &&
                IUpdateable(liquidityAccumulator).timeSinceLastUpdate(data) >= period)
        ) {
            // Shouldn't update if the accumulators are not up-to-date
            return false;
        }

        address token = abi.decode(data, (address));

        if (
            ILiquidityAccumulator(liquidityAccumulator).getLastAccumulation(token).timestamp == 0 ||
            IPriceAccumulator(priceAccumulator).getLastAccumulation(token).timestamp == 0
        ) {
            // Can't update if the accumulators haven't been initialized
            return false;
        }

        return super.canUpdate(data);
    }

    /// @inheritdoc AbstractOracle
    function lastUpdateTime(bytes memory data) public view virtual override returns (uint256) {
        address token = abi.decode(data, (address));

        // Note: We ignore the last observation timestamp because it always updates when the accumulation timestamps
        // update.
        uint256 lastPriceAccumulationTimestamp = priceAccumulations[token].timestamp;
        uint256 lastLiquidityAccumulationTimestamp = liquidityAccumulations[token].timestamp;

        return Math.max(lastPriceAccumulationTimestamp, lastLiquidityAccumulationTimestamp);
    }

    /// @inheritdoc PeriodicOracle
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return
            interfaceId == type(IHasLiquidityAccumulator).interfaceId ||
            interfaceId == type(IHasPriceAccumulator).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function performUpdate(bytes memory data) internal virtual override returns (bool) {
        // We require that the accumulators do not need updates, or if they do, that they've been updated within the
        // last period (i.e. they are up-to-date).
        // If they are not up-to-date, the oracle will not update.
        // It is expected that oracle consumers will check the last update time before using the data as to avoid using
        // stale data.
        require(
            IUpdateable(priceAccumulator).timeSinceLastUpdate(data) < period ||
                !IUpdateable(priceAccumulator).needsUpdate(data),
            "PeriodicAccumulationOracle: PRICE_ACCUMULATOR_NEEDS_UPDATE"
        );
        require(
            IUpdateable(liquidityAccumulator).timeSinceLastUpdate(data) < period ||
                !IUpdateable(liquidityAccumulator).needsUpdate(data),
            "PeriodicAccumulationOracle: LIQUIDITY_ACCUMULATOR_NEEDS_UPDATE"
        );

        address token = abi.decode(data, (address));

        ObservationLibrary.Observation storage observation = observations[token];

        bool updatedObservation;
        bool missingPrice;
        bool anythingUpdated;

        /*
         * 1. Update price
         */
        {
            AccumulationLibrary.PriceAccumulator memory freshAccumulation = IPriceAccumulator(priceAccumulator)
                .getCurrentAccumulation(token);

            AccumulationLibrary.PriceAccumulator storage lastAccumulation = priceAccumulations[token];

            uint256 lastAccumulationTime = priceAccumulations[token].timestamp;

            if (freshAccumulation.timestamp > lastAccumulationTime) {
                // Accumulator updated, so we update our observation

                if (lastAccumulationTime != 0) {
                    // We have two accumulations -> calculate price from them
                    observation.price = IPriceAccumulator(priceAccumulator).calculatePrice(
                        lastAccumulation,
                        freshAccumulation
                    );

                    updatedObservation = true;
                } else {
                    // This is our first update (or rather, we have our first accumulation)
                    // Record that we're missing the price to later prevent the observation timestamp and event
                    // from being emitted (no timestamp = missing observation and consult reverts).
                    missingPrice = true;
                }

                lastAccumulation.cumulativePrice = freshAccumulation.cumulativePrice;
                lastAccumulation.timestamp = freshAccumulation.timestamp;

                anythingUpdated = true;
            }
        }

        /*
         * 2. Update liquidity
         */
        {
            AccumulationLibrary.LiquidityAccumulator memory freshAccumulation = ILiquidityAccumulator(
                liquidityAccumulator
            ).getCurrentAccumulation(token);

            AccumulationLibrary.LiquidityAccumulator storage lastAccumulation = liquidityAccumulations[token];

            uint256 lastAccumulationTime = liquidityAccumulations[token].timestamp;

            if (freshAccumulation.timestamp > lastAccumulationTime) {
                // Accumulator updated, so we update our observation

                if (lastAccumulationTime != 0) {
                    // We have two accumulations -> calculate liquidity from them
                    (observation.tokenLiquidity, observation.quoteTokenLiquidity) = ILiquidityAccumulator(
                        liquidityAccumulator
                    ).calculateLiquidity(lastAccumulation, freshAccumulation);

                    updatedObservation = true;
                }

                lastAccumulation.cumulativeTokenLiquidity = freshAccumulation.cumulativeTokenLiquidity;
                lastAccumulation.cumulativeQuoteTokenLiquidity = freshAccumulation.cumulativeQuoteTokenLiquidity;
                lastAccumulation.timestamp = freshAccumulation.timestamp;

                anythingUpdated = true;
            }
        }

        // We only want to update the timestamp and emit an event when both the observation has been updated and we
        // have a price (even if the accumulator calculates a price of 0).
        // Note: We rely on consult reverting when the observation timestamp is 0.
        if (updatedObservation && !missingPrice) {
            observation.timestamp = block.timestamp.toUint32();

            emit Updated(
                token,
                observation.price,
                observation.tokenLiquidity,
                observation.quoteTokenLiquidity,
                block.timestamp
            );
        }

        return anythingUpdated;
    }

    /// @inheritdoc AbstractOracle
    function instantFetch(address token)
        internal
        view
        virtual
        override
        returns (
            uint112 price,
            uint112 tokenLiquidity,
            uint112 quoteTokenLiquidity
        )
    {
        // We assume the accumulators are also oracles... the interfaces need to be refactored
        price = IPriceOracle(priceAccumulator).consultPrice(token, 0);
        (tokenLiquidity, quoteTokenLiquidity) = ILiquidityOracle(liquidityAccumulator).consultLiquidity(token, 0);
    }
}