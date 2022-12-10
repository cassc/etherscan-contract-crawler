// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.15;

import {AggregatorV2V3Interface} from "interfaces/AggregatorV2V3Interface.sol";
import "src/Kernel.sol";

/// @notice Price oracle data storage
/// @dev    The Olympus Price Oracle contract provides a standard interface for OHM price data against a reserve asset.
///         It also implements a moving average price calculation (same as a TWAP) on the price feed data over a configured
///         duration and observation frequency. The data provided by this contract is used by the Olympus Range Operator to
///         perform market operations. The Olympus Price Oracle is updated each epoch by the Olympus Heart contract.
abstract contract PRICEv1 is Module {
    // =========  EVENTS ========= //

    event NewObservation(uint256 timestamp_, uint256 price_, uint256 movingAverage_);
    event MovingAverageDurationChanged(uint48 movingAverageDuration_);
    event ObservationFrequencyChanged(uint48 observationFrequency_);
    event UpdateThresholdsChanged(uint48 ohmEthUpdateThreshold_, uint48 reserveEthUpdateThreshold_);
    event MinimumTargetPriceChanged(uint256 minimumTargetPrice_);

    // =========  ERRORS ========= //

    error Price_InvalidParams();
    error Price_NotInitialized();
    error Price_AlreadyInitialized();
    error Price_BadFeed(address priceFeed);

    // =========  STATE ========= //

    /// @dev    Price feeds. Chainlink typically provides price feeds for an asset in ETH. Therefore, we use two price feeds against ETH, one for OHM and one for the Reserve asset, to calculate the relative price of OHM in the Reserve asset.
    /// @dev    Update thresholds are the maximum amount of time that can pass between price feed updates before the price oracle is considered stale. These should be set based on the parameters of the price feed.

    /// @notice OHM/ETH price feed
    AggregatorV2V3Interface public ohmEthPriceFeed;

    /// @notice Maximum expected time between OHM/ETH price feed updates
    uint48 public ohmEthUpdateThreshold;

    /// @notice Reserve/ETH price feed
    AggregatorV2V3Interface public reserveEthPriceFeed;

    /// @notice Maximum expected time between OHM/ETH price feed updates
    uint48 public reserveEthUpdateThreshold;

    /// @notice    Running sum of observations to calculate the moving average price from
    /// @dev       See getMovingAverage()
    uint256 public cumulativeObs;

    /// @notice Array of price observations. Check nextObsIndex to determine latest data point.
    /// @dev    Observations are stored in a ring buffer where the moving average is the sum of all observations divided by the number of observations.
    ///         Observations can be cleared by changing the movingAverageDuration or observationFrequency and must be re-initialized.
    uint256[] public observations;

    /// @notice Index of the next observation to make. The current value at this index is the oldest observation.
    uint32 public nextObsIndex;

    /// @notice Number of observations used in the moving average calculation. Computed from movingAverageDuration / observationFrequency.
    uint32 public numObservations;

    /// @notice Frequency (in seconds) that observations should be stored.
    uint48 public observationFrequency;

    /// @notice Duration (in seconds) over which the moving average is calculated.
    uint48 public movingAverageDuration;

    /// @notice Unix timestamp of last observation (in seconds).
    uint48 public lastObservationTime;

    /// @notice Whether the price module is initialized (and therefore active).
    bool public initialized;

    /// @notice Number of decimals in the price values provided by the contract.
    uint8 public constant decimals = 18;

    /// @notice Minimum target price for RBS system. Set manually to correspond to the liquid backing of OHM.
    uint256 public minimumTargetPrice;

    // =========  FUNCTIONS ========= //

    /// @notice Trigger an update of the moving average. Permissioned.
    /// @dev    This function does not have a time-gating on the observationFrequency on this contract. It is set on the Heart policy contract.
    ///         The Heart beat frequency should be set to the same value as the observationFrequency.
    function updateMovingAverage() external virtual;

    /// @notice Initialize the price module
    /// @notice Access restricted to activated policies
    /// @param  startObservations_ - Array of observations to initialize the moving average with. Must be of length numObservations.
    /// @param  lastObservationTime_ - Unix timestamp of last observation being provided (in seconds).
    /// @dev    This function must be called after the Price module is deployed to activate it and after updating the observationFrequency
    ///         or movingAverageDuration (in certain cases) in order for the Price module to function properly.
    function initialize(uint256[] memory startObservations_, uint48 lastObservationTime_)
        external
        virtual;

    /// @notice Change the moving average window (duration)
    /// @param  movingAverageDuration_ - Moving average duration in seconds, must be a multiple of observation frequency
    /// @dev    Changing the moving average duration will erase the current observations array
    ///         and require the initialize function to be called again. Ensure that you have saved
    ///         the existing data and can re-populate before calling this function.
    function changeMovingAverageDuration(uint48 movingAverageDuration_) external virtual;

    /// @notice   Change the observation frequency of the moving average (i.e. how often a new observation is taken)
    /// @param    observationFrequency_ - Observation frequency in seconds, must be a divisor of the moving average duration
    /// @dev      Changing the observation frequency clears existing observation data since it will not be taken at the right time intervals.
    ///           Ensure that you have saved the existing data and/or can re-populate before calling this function.
    function changeObservationFrequency(uint48 observationFrequency_) external virtual;

    /// @notice   Change the update thresholds for the price feeds
    /// @param    ohmEthUpdateThreshold_ - Maximum allowed time between OHM/ETH price feed updates
    /// @param    reserveEthUpdateThreshold_ - Maximum allowed time between Reserve/ETH price feed updates
    /// @dev      The update thresholds should be set based on the update threshold of the chainlink oracles.
    function changeUpdateThresholds(
        uint48 ohmEthUpdateThreshold_,
        uint48 reserveEthUpdateThreshold_
    ) external virtual;

    /// @notice   Change the minimum target price
    /// @param    minimumTargetPrice_ - Minimum target price for RBS system with 18 decimals, expressed as number of Reserve per OHM
    /// @dev      The minimum target price should be set based on the liquid backing of OHM.
    function changeMinimumTargetPrice(uint256 minimumTargetPrice_) external virtual;

    /// @notice Get the current price of OHM in the Reserve asset from the price feeds
    function getCurrentPrice() external view virtual returns (uint256);

    /// @notice Get the last stored price observation of OHM in the Reserve asset
    function getLastPrice() external view virtual returns (uint256);

    /// @notice Get the moving average of OHM in the Reserve asset over the defined window (see movingAverageDuration and observationFrequency).
    function getMovingAverage() external view virtual returns (uint256);

    /// @notice Get target price of OHM in the Reserve asset for the RBS system
    /// @dev    Returns the maximum of the moving average and the minimum target price
    function getTargetPrice() external view virtual returns (uint256);
}