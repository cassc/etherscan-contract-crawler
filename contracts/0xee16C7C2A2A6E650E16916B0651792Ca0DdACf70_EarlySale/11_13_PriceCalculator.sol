// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract PriceCalculator {
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    /**
     * @notice View the price of STK tokens in USD
     */
    function STK_USD_VALUE() public view virtual returns (uint256);

    /**
     * @notice View the number of decimals (precision) for `STK_USD_VALUE`
     */
    function STK_USD_DECIMALS() public view virtual returns (uint8);

    /**
     * @notice Converts an ETH value to STK
     * @param _eth, the value to convert
     */
    function getPriceConversion(uint256 _eth) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return
            (uint256(price) * _eth * 10 ** STK_USD_DECIMALS()) /
            STK_USD_VALUE() /
            10 ** priceFeed.decimals();
    }
}