// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract PriceCalculator {
    AggregatorV3Interface internal priceFeed;

    /**
     * @dev Define the price of STK token in USD
     *      - 1 STK = 1/10 $ => 1 STK = 0.1 $
     */
    uint8 public STK_USD_VALUE = 1;
    uint8 internal constant STK_USD_RATIO = 10;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice convert WEI => STK
     * @param _value, the value to convert
     */
    function getPriceConversion(uint256 _value)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 priceUSD = uint256(price) * 1e10 * _value;
        return priceUSD / ((STK_USD_VALUE * 1e18) / STK_USD_RATIO);
        // STK
    }
}