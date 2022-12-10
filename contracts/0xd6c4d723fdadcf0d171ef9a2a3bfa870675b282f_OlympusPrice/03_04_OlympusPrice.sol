// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {AggregatorV2V3Interface} from "interfaces/AggregatorV2V3Interface.sol";

import {PRICEv1} from "src/modules/PRICE/PRICE.v1.sol";
import "src/Kernel.sol";

/// @notice Price oracle data storage contract.
contract OlympusPrice is PRICEv1 {
    // =========  STATE ========= //

    // Scale factor for converting prices, calculated from decimal values.
    uint256 internal immutable _scaleFactor;

    //============================================================================================//
    //                                        MODULE SETUP                                        //
    //============================================================================================//

    constructor(
        Kernel kernel_,
        AggregatorV2V3Interface ohmEthPriceFeed_,
        uint48 ohmEthUpdateThreshold_,
        AggregatorV2V3Interface reserveEthPriceFeed_,
        uint48 reserveEthUpdateThreshold_,
        uint48 observationFrequency_,
        uint48 movingAverageDuration_,
        uint256 minimumTargetPrice_
    ) Module(kernel_) {
        /// @dev Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (movingAverageDuration_ == 0 || movingAverageDuration_ % observationFrequency_ != 0)
            revert Price_InvalidParams();

        // Set price feeds, decimals, and scale factor
        ohmEthPriceFeed = ohmEthPriceFeed_;
        ohmEthUpdateThreshold = ohmEthUpdateThreshold_;
        uint8 ohmEthDecimals = ohmEthPriceFeed.decimals();

        reserveEthPriceFeed = reserveEthPriceFeed_;
        reserveEthUpdateThreshold = reserveEthUpdateThreshold_;
        uint8 reserveEthDecimals = reserveEthPriceFeed.decimals();

        uint256 exponent = decimals + reserveEthDecimals - ohmEthDecimals;
        if (exponent > 38) revert Price_InvalidParams();
        _scaleFactor = 10**exponent;

        // Set parameters and calculate number of observations
        observationFrequency = observationFrequency_;
        movingAverageDuration = movingAverageDuration_;

        numObservations = uint32(movingAverageDuration_ / observationFrequency_);

        // Store blank observations array
        observations = new uint256[](numObservations);
        // nextObsIndex is initialized to 0

        // Set minimum target price
        minimumTargetPrice = minimumTargetPrice_;

        emit MovingAverageDurationChanged(movingAverageDuration_);
        emit ObservationFrequencyChanged(observationFrequency_);
        emit UpdateThresholdsChanged(ohmEthUpdateThreshold_, reserveEthUpdateThreshold_);
        emit MinimumTargetPriceChanged(minimumTargetPrice_);
    }

    /// @inheritdoc Module
    function KEYCODE() public pure override returns (Keycode) {
        return toKeycode("PRICE");
    }

    /// @inheritdoc Module
    function VERSION() external pure override returns (uint8 major, uint8 minor) {
        major = 1;
        minor = 1;
    }

    //============================================================================================//
    //                                       CORE FUNCTIONS                                       //
    //============================================================================================//

    /// @inheritdoc PRICEv1
    function updateMovingAverage() external override permissioned {
        // Revert if not initialized
        if (!initialized) revert Price_NotInitialized();

        // Cache numbe of observations to save gas.
        uint32 numObs = numObservations;

        // Get earliest observation in window
        uint256 earliestPrice = observations[nextObsIndex];

        uint256 currentPrice = getCurrentPrice();

        // Calculate new cumulative observation total
        cumulativeObs = cumulativeObs + currentPrice - earliestPrice;

        // Push new observation into storage and store timestamp taken at
        observations[nextObsIndex] = currentPrice;
        lastObservationTime = uint48(block.timestamp);
        nextObsIndex = (nextObsIndex + 1) % numObs;

        emit NewObservation(block.timestamp, currentPrice, getMovingAverage());
    }

    /// @inheritdoc PRICEv1
    function initialize(uint256[] memory startObservations_, uint48 lastObservationTime_)
        external
        override
        permissioned
    {
        if (initialized) revert Price_AlreadyInitialized();

        // Cache numObservations to save gas.
        uint256 numObs = observations.length;

        // Check that the number of start observations matches the number expected
        if (startObservations_.length != numObs || lastObservationTime_ > uint48(block.timestamp))
            revert Price_InvalidParams();

        // Push start observations into storage and total up observations
        uint256 total;
        for (uint256 i; i < numObs; ) {
            if (startObservations_[i] == 0) revert Price_InvalidParams();
            total += startObservations_[i];
            observations[i] = startObservations_[i];
            unchecked {
                ++i;
            }
        }

        // Set cumulative observations, last observation time, and initialized flag
        cumulativeObs = total;
        lastObservationTime = lastObservationTime_;
        initialized = true;
    }

    /// @inheritdoc PRICEv1
    function changeMovingAverageDuration(uint48 movingAverageDuration_)
        external
        override
        permissioned
    {
        // Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (movingAverageDuration_ == 0 || movingAverageDuration_ % observationFrequency != 0)
            revert Price_InvalidParams();

        // Calculate the new number of observations
        uint256 newObservations = uint256(movingAverageDuration_ / observationFrequency);

        // Store blank observations array of new size
        observations = new uint256[](newObservations);

        // Set initialized to false and update state variables
        initialized = false;
        lastObservationTime = 0;
        cumulativeObs = 0;
        nextObsIndex = 0;
        movingAverageDuration = movingAverageDuration_;
        numObservations = uint32(newObservations);

        emit MovingAverageDurationChanged(movingAverageDuration_);
    }

    /// @inheritdoc PRICEv1
    function changeObservationFrequency(uint48 observationFrequency_)
        external
        override
        permissioned
    {
        // Moving Average Duration should be divisible by Observation Frequency to get a whole number of observations
        if (observationFrequency_ == 0 || movingAverageDuration % observationFrequency_ != 0)
            revert Price_InvalidParams();

        // Calculate the new number of observations
        uint256 newObservations = uint256(movingAverageDuration / observationFrequency_);

        // Since the old observations will not be taken at the right intervals,
        // the observations array will need to be reinitialized.
        // Although, there are a handful of situations that could be handled
        // (e.g. clean multiples of the old frequency),
        // it is easier to do so off-chain and reinitialize the array.

        // Store blank observations array of new size
        observations = new uint256[](newObservations);

        // Set initialized to false and update state variables
        initialized = false;
        lastObservationTime = 0;
        cumulativeObs = 0;
        nextObsIndex = 0;
        observationFrequency = observationFrequency_;
        numObservations = uint32(newObservations);

        emit ObservationFrequencyChanged(observationFrequency_);
    }

    function changeUpdateThresholds(
        uint48 ohmEthUpdateThreshold_,
        uint48 reserveEthUpdateThreshold_
    ) external override permissioned {
        ohmEthUpdateThreshold = ohmEthUpdateThreshold_;
        reserveEthUpdateThreshold = reserveEthUpdateThreshold_;

        emit UpdateThresholdsChanged(ohmEthUpdateThreshold_, reserveEthUpdateThreshold_);
    }

    function changeMinimumTargetPrice(uint256 minimumTargetPrice_) external override permissioned {
        minimumTargetPrice = minimumTargetPrice_;

        emit MinimumTargetPriceChanged(minimumTargetPrice_);
    }

    //============================================================================================//
    //                                      VIEW FUNCTIONS                                        //
    //============================================================================================//

    /// @inheritdoc PRICEv1
    function getCurrentPrice() public view override returns (uint256) {
        if (!initialized) revert Price_NotInitialized();

        // Get prices from feeds
        uint256 ohmEthPrice;
        uint256 reserveEthPrice;
        {
            (
                uint80 roundId,
                int256 ohmEthPriceInt,
                ,
                uint256 updatedAt,
                uint80 answeredInRound
            ) = ohmEthPriceFeed.latestRoundData();

            // Validate chainlink price feed data
            // 1. Answer should be greater than zero
            // 2. Updated at timestamp should be within the update threshold
            // 3. Answered in round ID should be the same as the round ID
            if (
                ohmEthPriceInt <= 0 ||
                updatedAt < block.timestamp - uint256(ohmEthUpdateThreshold) ||
                answeredInRound != roundId
            ) revert Price_BadFeed(address(ohmEthPriceFeed));
            ohmEthPrice = uint256(ohmEthPriceInt);

            int256 reserveEthPriceInt;
            (roundId, reserveEthPriceInt, , updatedAt, answeredInRound) = reserveEthPriceFeed
                .latestRoundData();
            if (
                reserveEthPriceInt <= 0 ||
                updatedAt < block.timestamp - uint256(reserveEthUpdateThreshold) ||
                answeredInRound != roundId
            ) revert Price_BadFeed(address(reserveEthPriceFeed));
            reserveEthPrice = uint256(reserveEthPriceInt);
        }

        // Convert to OHM/RESERVE price
        uint256 currentPrice = (ohmEthPrice * _scaleFactor) / reserveEthPrice;

        return currentPrice;
    }

    /// @inheritdoc PRICEv1
    function getLastPrice() external view override returns (uint256) {
        if (!initialized) revert Price_NotInitialized();
        uint32 lastIndex = nextObsIndex == 0 ? numObservations - 1 : nextObsIndex - 1;
        return observations[lastIndex];
    }

    /// @inheritdoc PRICEv1
    function getMovingAverage() public view override returns (uint256) {
        if (!initialized) revert Price_NotInitialized();
        return cumulativeObs / numObservations;
    }

    /// @inheritdoc PRICEv1
    function getTargetPrice() external view override returns (uint256) {
        uint256 movingAverage = getMovingAverage();
        return movingAverage > minimumTargetPrice ? movingAverage : minimumTargetPrice;
    }
}