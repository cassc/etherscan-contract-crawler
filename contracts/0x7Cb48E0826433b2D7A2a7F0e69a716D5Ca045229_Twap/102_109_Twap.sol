// SPDX-License-Identifier: MIT

pragma solidity =0.7.6;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "../external-lib/UniswapV2Library.sol";
import "../external-lib/UniswapV2OracleLibrary.sol";
import "../lib/SushiswapLibrary.sol";

import "./interfaces/ITwap.sol";

// As these are "Time"-Weighted Average Price contracts, they necessarily rely on time.
// solhint-disable not-rely-on-time

/**
 * @title A sliding window for AMMs (specifically Sushiswap)
 * @notice Uses observations collected over a window to provide moving price averages in the past
 * @dev This is a singleton TWAP that only needs to be deployed once per desired parameters. `windowSize` has a precision of `windowSize / granularity`
 * Errors:
 * MissingPastObsr   - We do not have suffient past observations.
 * UnexpectedElapsed - We have an unexpected time elapsed.
 * EarlyUpdate       - Tried to update the TWAP before the period has elapsed.
 * InvalidToken      - Cannot consult an invalid token pair.
 */
contract Twap is ITwap {
  using FixedPoint for *;
  using SafeMath for uint256;

  struct Observation {
    uint256 timestamp;
    uint256 price0Cumulative;
    uint256 price1Cumulative;
  }

  /* ========== IMMUTABLE VARIABLES ========== */

  /// @notice the Uniswap Factory contract for tracking exchanges
  address public immutable factory;

  /// @notice The desired amount of time over which the moving average should be computed, e.g. 24 hours
  uint256 public immutable windowSize;

  /// @notice The number of observations stored for each pair, i.e. how many price observations are stored for the window
  /// @dev As granularity increases from, more frequent updates are needed; but precision increases [`windowSize - (windowSize / granularity) * 2`, `windowSize`]
  uint8 public immutable granularity;

  /// @dev Redundant with `granularity` and `windowSize`, but has gas savings & easy read
  uint256 public immutable periodSize;

  /* ========== STATE VARIABLES ========== */

  /// @notice Mapping from pair address to a list of price observations of that pair
  mapping(address => Observation[]) public pairObservations;

  /* ========== EVENTS ========== */

  event NewObservation(
    uint256 timestamp,
    uint256 price0Cumulative,
    uint256 price1Cumulative
  );

  /* ========== CONSTRUCTOR ========== */

  /**
   * @notice Construct a new Sliding Window TWAP
   * @param factory_ The AMM factory
   * @param windowSize_ The window size for this TWAP
   * @param granularity_ The granularity required for the TWAP
   */
  constructor(
    address factory_,
    uint256 windowSize_,
    uint8 granularity_
  ) {
    require(factory_ != address(0), "Twap/InvalidFactory");
    require(granularity_ > 1, "Twap/Granularity");
    require(
      (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
      "Twap/WindowSize"
    );
    factory = factory_;
    windowSize = windowSize_;
    granularity = granularity_;
  }

  /* ========== PURE ========== */

  /**
   * @notice Given the cumulative prices of the start and end of a period, and the length of the period, compute the average price in terms of the amount in
   * @param priceCumulativeStart the cumulative price for the start of the period
   * @param priceCumulativeEnd the cumulative price for the end of the period
   * @param timeElapsed the time from now to the first observation
   * @param amountIn the amount of tokens in
   * @return amountOut amount out received for the amount in
   */
  function _computeAmountOut(
    uint256 priceCumulativeStart,
    uint256 priceCumulativeEnd,
    uint256 timeElapsed,
    uint256 amountIn
  ) private pure returns (uint256 amountOut) {
    // overflow is desired.
    FixedPoint.uq112x112 memory priceAverage =
      FixedPoint.uq112x112(
        uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
      );
    amountOut = priceAverage.mul(amountIn).decode144();
  }

  /* ========== VIEWS ========== */

  /**
   * @notice Calculates the index of the observation for the given `timestamp`
   * @param timestamp the observation for the timestamp
   * @return index The index of the observation
   */
  function observationIndexOf(uint256 timestamp)
    public
    view
    returns (uint8 index)
  {
    uint256 epochPeriod = timestamp / periodSize;
    return uint8(epochPeriod % granularity);
  }

  /// @inheritdoc ITwap
  function updateable(address tokenA, address tokenB)
    external
    view
    override(ITwap)
    returns (bool)
  {
    address pair = SushiswapLibrary.pairFor(factory, tokenA, tokenB);

    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    // We only want to commit updates once per period (i.e. windowSize / granularity).
    uint256 timeElapsed = block.timestamp - observation.timestamp;

    return timeElapsed > periodSize;
  }

  /// @inheritdoc ITwap
  function consult(
    address tokenIn,
    uint256 amountIn,
    address tokenOut
  ) external view override(ITwap) returns (uint256 amountOut) {
    address pair = SushiswapLibrary.pairFor(factory, tokenIn, tokenOut);
    Observation storage firstObservation = _getFirstObservationInWindow(pair);

    uint256 timeElapsed = block.timestamp - firstObservation.timestamp;
    require(timeElapsed <= windowSize, "Twap/MissingPastObsr");
    require(
      timeElapsed >= windowSize - periodSize * 2,
      "Twap/UnexpectedElapsed"
    );

    (uint256 price0Cumulative, uint256 price1Cumulative, ) =
      UniswapV2OracleLibrary.currentCumulativePrices(pair);
    (address token0, address token1) =
      UniswapV2Library.sortTokens(tokenIn, tokenOut);

    if (token0 == tokenIn) {
      return
        _computeAmountOut(
          firstObservation.price0Cumulative,
          price0Cumulative,
          timeElapsed,
          amountIn
        );
    }

    require(token1 == tokenIn, "Twap/InvalidToken");

    return
      _computeAmountOut(
        firstObservation.price1Cumulative,
        price1Cumulative,
        timeElapsed,
        amountIn
      );
  }

  /**
   * @notice Observation from the oldest epoch (at the beginning of the window) relative to the current time
   * @param pair the Uniswap pair address
   * @return firstObservation The observation from the oldest epoch relative to current time.
   */
  function _getFirstObservationInWindow(address pair)
    private
    view
    returns (Observation storage firstObservation)
  {
    uint8 observationIndex = observationIndexOf(block.timestamp);
    // No overflow issues; if observationIndex + 1 overflows, result is still zero.
    uint8 firstObservationIndex = (observationIndex + 1) % granularity;
    firstObservation = pairObservations[pair][firstObservationIndex];
  }

  /* ========== MUTATIVE FUNCTIONS ========== */

  /// @inheritdoc ITwap
  function update(address tokenA, address tokenB)
    external
    override(ITwap)
    returns (bool)
  {
    address pair = SushiswapLibrary.pairFor(factory, tokenA, tokenB);

    // Populate the array with empty observations for the first call.
    for (uint256 i = pairObservations[pair].length; i < granularity; i++) {
      pairObservations[pair].push();
    }

    // Get the observation for the current period.
    uint8 observationIndex = observationIndexOf(block.timestamp);
    Observation storage observation = pairObservations[pair][observationIndex];

    // We only want to commit updates once per period (i.e. windowSize / granularity).
    uint256 timeElapsed = block.timestamp - observation.timestamp;

    if (timeElapsed <= periodSize) {
      // Skip update as we're in the same observation slot.
      return false;
    }

    (uint256 price0Cumulative, uint256 price1Cumulative, ) =
      UniswapV2OracleLibrary.currentCumulativePrices(pair);
    observation.timestamp = block.timestamp;
    observation.price0Cumulative = price0Cumulative;
    observation.price1Cumulative = price1Cumulative;

    emit NewObservation(
      observation.timestamp,
      observation.price0Cumulative,
      observation.price1Cumulative
    );

    return true;
  }
}