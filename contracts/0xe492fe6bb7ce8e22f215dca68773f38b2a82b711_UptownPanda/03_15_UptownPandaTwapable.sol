// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "@uniswap/lib/contracts/libraries/FixedPoint.sol";
import "./interfaces/IUniswapV2Oracle.sol";

contract UptownPandaTwapable {
    using FixedPoint for *;

    event TwapUpdated(uint256 newTwap, uint256 priceCumulative, uint32 blockTimestamp);

    uint256 public constant LISTING_PRICE_MULTIPLIER = 11;
    uint256 public constant TWAP_CALCULATION_INTERVAL = 10 minutes;

    bool private isListingTwapSet;
    bool private isInitialized;
    bool private isTokenToken0; // is our token first after sorting
    address private uniswapPair;
    IUniswapV2Oracle private oracle;

    uint32 public currentTwapTimestamp;
    uint256 public currentTwapPriceCumulative;
    uint256 public currentTwap;

    constructor() public {
        isListingTwapSet = false;
        isInitialized = false;
    }

    modifier initialized() {
        require(isInitialized, "TWAP data required for calculation has not been set yet.");
        _;
    }

    modifier listingTwapSet() {
        require(isListingTwapSet, "Listing TWAP has not been set yet.");
        _;
    }

    function _initializeTwap(
        bool _isTokenToken0,
        address _uniswapPair,
        address _oracle
    ) internal {
        isTokenToken0 = _isTokenToken0;
        uniswapPair = _uniswapPair;
        oracle = IUniswapV2Oracle(_oracle);
        isInitialized = true;
    }

    function _setListingTwap() internal {
        if (isListingTwapSet) {
            return;
        }
        (uint256 priceCumulative, uint32 timestamp) = _currentCumulativePrices();
        _setTwapValuesAndTriggerUpdateEvent(_getListingPrice(), priceCumulative, timestamp);
        isListingTwapSet = true;
    }

    function _updateTwap() internal initialized listingTwapSet {
        (uint256 priceCumulative, uint32 timestamp) = _currentCumulativePrices();

        uint32 timeElapsed = timestamp - currentTwapTimestamp;
        if (timeElapsed < TWAP_CALCULATION_INTERVAL) {
            return;
        }

        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        FixedPoint.uq112x112 memory newTwapAsFixedPoint = FixedPoint.uq112x112(
            uint224((priceCumulative - currentTwapPriceCumulative) / timeElapsed)
        );
        uint144 newTwap = newTwapAsFixedPoint.mul(1 ether).decode144();
        _setTwapValuesAndTriggerUpdateEvent(newTwap, priceCumulative, timestamp);
    }

    function _setTwapValuesAndTriggerUpdateEvent(
        uint256 _currentTwap,
        uint256 _currentTwapPriceCumulative,
        uint32 _currentTwapTimestamp
    ) private {
        currentTwap = _currentTwap;
        currentTwapPriceCumulative = _currentTwapPriceCumulative;
        currentTwapTimestamp = _currentTwapTimestamp;
        emit TwapUpdated(currentTwap, currentTwapPriceCumulative, currentTwapTimestamp);
    }

    function _currentCumulativePrices() private view returns (uint256 priceCumulative, uint32 timestamp) {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = oracle.currentCumulativePrices(
            uniswapPair
        );
        priceCumulative = isTokenToken0 ? price1Cumulative : price0Cumulative;
        timestamp = blockTimestamp;
    }

    function _getListingPrice() internal pure returns (uint256) {
        return LISTING_PRICE_MULTIPLIER * 1 ether;
    }
}