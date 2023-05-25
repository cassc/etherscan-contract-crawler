// SPDX-License-Identifier:  AGPL-3.0-or-later
pragma solidity 0.8.18;

import {IUtils} from "IUtils.sol";
import {AggregatorV3Interface} from "AggregatorV3Interface.sol";
import "Multicall.sol";
/**
* @title Utils
* @author aarora
* @notice Utils provides utilities functions for performing conversions between ETH and USD,
*         determining whether two values are close to each other by a certain threshold or not.
*         This utilities are used to facilitate marketplace transactions.
*/
contract Utils is IUtils, Multicall {

    AggregatorV3Interface internal priceFeed;
    bytes32 public constant USD_CURRENCY = keccak256("USD");
    bytes32 public constant ETH_CURRENCY = keccak256("ETH");

    constructor (address priceFeedAddress) {
        require(priceFeedAddress != address(0), "Price feed aggregator address cannot be 0");

        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * @notice Utility for getting the bytes value of USD. Used for creating a listing.
     *
     * @return USDCurrency bytes32
     */
    function getUSDCurrencyBytes() external pure returns (bytes32 USDCurrency) {
        return USD_CURRENCY;
    }

    /**
     * @notice Utility for getting the bytes value of ETH. Used for creating a listing.
     *
     * @return ETHCurrency bytes32
     */
    function getETHCurrencyBytes() external pure returns (bytes32 ETHCurrency) {
        return ETH_CURRENCY;
    }

    /**
     * @notice Utility for retrieving ETH Price in USD from Chainlink oracle.
     *
     * @return ETHPriceInUSD Price of 1 ETH in USD
     */
    function getETHPriceInUSD() external view returns (uint256 ETHPriceInUSD) {
        return _getETHPriceInUSD();
    }

    /**
     * @notice Utility for converting USD cents padded by 1e18 (Wei representation) to ETH Wei.
     *
     * @param amountInUSD USD value in cents padded by 1e18 (Wei representation).
     *
     * @return ETHWei ETH Value in Wei of USD cents value padded by 1e18
     */
    function convertUSDWeiToETHWei(uint256 amountInUSD) external view returns(uint256 ETHWei) {
        return _convertUSDWeiToETHWei(amountInUSD);
    }

    /**
     * @notice Utility for converting ETH Wei to USD cents padded by 1e18 (Wei representation).
     *
     * @param amountInETH ETH value in Wei.
     *
     * @return USDWei USD cents padded by 1e18 value of ETH Wei
     */
    function convertETHWeiToUSDWei(uint256 amountInETH) external view returns(uint256 USDWei) {
        return _convertETHWeiToUSDWei(amountInETH);
    }

    /**
     * @notice Utility for comparing two values and determining whether they are close (based on the threshold %).
     *
     * @param originalAmount  Value to be considered the truth value.
     * @param compareToAmount Value to be tested. If this value is not within the threshold of the original value,
                              the function will return false.
     * @param threshold       Threshold for how close the above values need to be.
     *
     * @return valueIsClose boolean indicating whether two numbers are close or not.
     */
    function isClose(
        uint256 originalAmount,
        uint256 compareToAmount,
        uint256 threshold
    ) external pure returns (bool valueIsClose) {
        return _isClose(originalAmount, compareToAmount, threshold);
    }

    /**
     * @notice Internal function for retrieving ETH Price in USD from Chainlink oracle.
     *
     * @return ETHPriceInUSD Price of 1 ETH in USD
     */
    function _getETHPriceInUSD() internal view virtual returns(uint256 ETHPriceInUSD) {
        // Retrieve ETH Price in USD from Chainlink price feed.
        (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        //check for stale data being returned from Chainlink data feed
        require(answeredInRound <= roundId, "Stale data being returned. Please try again");
        require(updatedAt > block.timestamp - 1 hours, "Freshness check failed for ETH/USD Price Feed");

        uint256 ethPrice = uint256(answer);

        // Revert if price is 0.
        require(ethPrice > 0, "Utils: ETH/USD Price Unavailable");
        return ethPrice;
    }

    /**
     * @notice Internal function for converting ETH Wei to USD cents padded by 1e18 (Wei representation).
     *
     * @param amountInETH ETH value in Wei.
     *
     * @return USDWei USD cents padded by 1e18 value of ETH Wei
     */
    function _convertETHWeiToUSDWei(uint256 amountInETH) internal view returns(uint256 USDWei) {
        uint256 ETHPriceInUSD = _getETHPriceInUSD();
        uint256 USDAmount = (amountInETH * ETHPriceInUSD) / 1e8;
        return USDAmount;
    }

    /**
     * @notice Internal function for converting USD cents padded by 1e18 (Wei representation) to ETH Wei.
     *
     * @param amountInUSD USD value in cents padded by 1e18 (Wei representation).
     *
     * @return ETHWei ETH Value in Wei of USD cents value padded by 1e18
     */
    function _convertUSDWeiToETHWei(uint256 amountInUSD) internal view returns(uint256 ETHWei) {
        uint256 ETHPriceInUSD = _getETHPriceInUSD();
        uint256 ETHAmount = (amountInUSD * 1e8) / ETHPriceInUSD;
        return ETHAmount;
    }

    /**
     * @notice Internal function for comparing two values and determining whether
     *         they are close (based on the threshold %).
     *
     * @param originalAmount  Value to be considered the truth value.
     * @param compareToAmount Value to be tested. If this value is not within the threshold of the original value,
                              the function will return false.
     * @param threshold       Threshold for how close the above values need to be.
     *
     * @return valueIsClose boolean indicating whether two numbers are close or not.
     */
    function _isClose(
        uint256 originalAmount,
        uint256 compareToAmount,
        uint256 threshold
    ) internal pure returns (bool valueIsClose) {
        require(originalAmount != 0, "Original amount cannot be 0");
        require(compareToAmount != 0, "Compare to amount cannot be 0");
        int256 difference = (int(compareToAmount) - int(originalAmount)) * 10 ** 18;
        uint256 absDifference = uint256(difference >= 0 ? difference : -difference);
        uint256 percentageError = (absDifference / (originalAmount)) * 100;
        return percentageError <= (threshold * 10 ** 18);
    }
}