// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//** HFD Oracle */
//** Author: Aceson Decubate 2022.10 */

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {
    UniswapV2OracleLibrary,
    FixedPoint
} from "@uniswap/v2-periphery/contracts/libraries/UniswapV2OracleLibrary.sol";
import { IUniswapV2Pair } from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract SlidingWindowOracle {
    using FixedPoint for *;

    struct Observation {
        uint256 timestamp;
        uint256 price0Cumulative;
        uint256 price1Cumulative;
    }

    IUniswapV2Pair public immutable pair;

    // the desired amount of time over which the moving average should be computed, e.g. 24 hours
    uint256 public immutable windowSize;
    // the number of observations stored for each pair, i.e. how many price observations are stored for the window.
    // as granularity increases from 1, more frequent updates are needed, but moving averages become more precise.
    uint8 public immutable granularity;
    uint256 public immutable periodSize;
    Observation[] public pairObservations;

    event PriceUpdated(uint256 timestamp);

    constructor(uint256 _windowSize, uint8 _granularity, address _pair) {
        require(_granularity > 1, "SlidingWindowOracle: GRANULARITY");
        require(
            (periodSize = _windowSize / _granularity) * _granularity == _windowSize,
            "SlidingWindowOracle: WINDOW_NOT_EVENLY_DIVISIBLE"
        );
        windowSize = _windowSize;
        granularity = _granularity;
        pair = IUniswapV2Pair(_pair);

        // populate the array with empty observations
        for (uint256 i = 0; i < granularity; i++) {
            pairObservations.push();
        }
    }

    function observationIndexOf(uint256 timestamp) public view returns (uint8 index) {
        uint256 epochPeriod = timestamp / periodSize;
        return uint8(epochPeriod % granularity);
    }

    function getAllObservations() public view returns (Observation[] memory) {
        return pairObservations;
    }

    function getFirstObservationInWindow() public view returns (Observation memory firstObservation) {
        uint8 observationIndex = observationIndexOf(block.timestamp);
        uint8 firstObservationIndex = (observationIndex + 1) % granularity;
        firstObservation = pairObservations[firstObservationIndex];
    }

    function update() external {
        uint8 observationIndex = observationIndexOf(block.timestamp);
        Observation storage observation = pairObservations[observationIndex];

        // we only want to commit updates once per period (i.e. windowSize / granularity)
        uint256 timeElapsed = block.timestamp - observation.timestamp;
        if (timeElapsed > periodSize) {
            (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(
                address(pair)
            );
            observation.timestamp = block.timestamp;
            observation.price0Cumulative = price0Cumulative;
            observation.price1Cumulative = price1Cumulative;
        }

        emit PriceUpdated(block.timestamp);
    }

    // given the cumulative prices of the start and end of a period, and the length of the period, compute the average
    // price in terms of how much amount out is received for the amount in
    function computeAmountOut(
        uint256 priceCumulativeStart,
        uint256 priceCumulativeEnd,
        uint256 timeElapsed,
        uint256 amountIn
    ) private pure returns (uint256 amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    // returns the amount out corresponding to the amount in for a given token using the moving average over the time
    // range [now - [windowSize, windowSize - periodSize * 2], now]
    // update must have been called for the bucket corresponding to timestamp `now - windowSize`
    function consult(address tokenIn, uint256 amountIn, address tokenOut) public view returns (uint256 amountOut) {
        Observation memory firstObservation = getFirstObservationInWindow();

        uint256 timeElapsed = block.timestamp - firstObservation.timestamp;
        require(timeElapsed <= windowSize, "SlidingWindowOracle: MISSING_HISTORICAL_OBSERVATION");

        (uint256 price0Cumulative, uint256 price1Cumulative, ) = UniswapV2OracleLibrary.currentCumulativePrices(
            address(pair)
        );
        address token0 = tokenIn < tokenOut ? tokenIn : tokenOut;

        if (token0 == tokenIn) {
            return computeAmountOut(firstObservation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(firstObservation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }
}

contract HODLOracle is Ownable, SlidingWindowOracle {
    AggregatorV3Interface public priceFeed; //HFD/ETH
    bool internal isUsingChainlink;

    IERC20Metadata public immutable token;
    address public immutable weth;
    AggregatorV3Interface public immutable ethusd;
    AggregatorV3Interface public immutable usdcusd;
    AggregatorV3Interface public immutable usdtusd;

    event OracleChanged(address feed, bool isUsing);

    constructor(
        address _pair,
        address _token,
        address _weth,
        address _ethusd,
        address _usdcusd,
        address _usdtusd,
        uint256 _windowSize,
        uint8 _granularity
    ) SlidingWindowOracle(_windowSize, _granularity, _pair) {
        require(_pair != address(0) && _token != address(0), "HODL: Zero address");
        weth = _weth;
        ethusd = AggregatorV3Interface(_ethusd);
        usdcusd = AggregatorV3Interface(_usdcusd);
        usdtusd = AggregatorV3Interface(_usdtusd);
        token = IERC20Metadata(_token);
    }

    function setChainlink(address _feed, bool _isUsing) external onlyOwner {
        if (_isUsing) require(_feed != address(0), "HODL: Zero address");
        priceFeed = AggregatorV3Interface(_feed);
        isUsingChainlink = _isUsing;
        emit OracleChanged(_feed, _isUsing);
    }

    function getPriceInETH(uint256 tokenAmount) public view returns (uint256 ethAmount) {
        if (!isUsingChainlink) {
            ethAmount = consult(address(token), tokenAmount, weth);
        } else {
            //Price of 1 HFD including decimals
            (, int256 price, , , ) = priceFeed.latestRoundData();
            ethAmount = (uint256(price) * tokenAmount) / 10 ** token.decimals();
        }
    }

    function getPriceInUSDC(uint256 tokenAmount) public view returns (uint256 usdAmount) {
        uint256 ethAmount = getPriceInETH(tokenAmount);
        usdAmount = convertETHToUSDC(ethAmount);
    }

    function getPriceInUSDT(uint256 tokenAmount) public view returns (uint256 usdAmount) {
        uint256 ethAmount = getPriceInETH(tokenAmount);
        usdAmount = convertETHToUSDT(ethAmount);
    }

    function convertETHToUSDC(uint256 ethAmount) public view returns (uint256 usdAmount) {
        (, int256 ethPrice, , , ) = ethusd.latestRoundData();
        (, int256 usdcPrice, , , ) = usdcusd.latestRoundData();

        //USDC have 6 decimals, ETH have 18
        usdAmount = (uint256(ethPrice) * 10 ** 6 * ethAmount) / (10 ** 18 * uint256(usdcPrice));
    }

    function convertUSDCToETH(uint256 usdAmount) public view returns (uint256 ethAmount) {
        (, int256 ethPrice, , , ) = ethusd.latestRoundData();
        (, int256 usdcPrice, , , ) = usdcusd.latestRoundData();

        ethAmount = (10 ** 18 * uint256(usdcPrice) * usdAmount) / (uint256(ethPrice) * 10 ** 6);
    }

    function convertETHToUSDT(uint256 ethAmount) public view returns (uint256 usdAmount) {
        (, int256 ethPrice, , , ) = ethusd.latestRoundData();
        (, int256 usdtPrice, , , ) = usdtusd.latestRoundData();

        //USDT have 6 decimals, , ETH have 18
        usdAmount = (uint256(ethPrice) * 10 ** 6 * ethAmount) / (10 ** 18 * uint256(usdtPrice));
    }

    function convertUSDTToETH(uint256 usdAmount) public view returns (uint256 ethAmount) {
        (, int256 ethPrice, , , ) = ethusd.latestRoundData();
        (, int256 usdtPrice, , , ) = usdtusd.latestRoundData();

        ethAmount = (10 ** 18 * uint256(usdtPrice) * usdAmount) / (uint256(ethPrice) * 10 ** 6);
    }

    function convertUSDToETH(uint256 usdAmount) public view returns (uint256 ethAmount) {
        usdAmount = usdAmount * 100; //Converting to 8 decimals
        (, int256 ethPrice, , , ) = ethusd.latestRoundData();
        ethAmount = (usdAmount * 10 ** 18) / uint256(ethPrice);
    }
}