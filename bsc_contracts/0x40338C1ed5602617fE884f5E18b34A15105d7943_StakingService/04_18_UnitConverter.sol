// SPDX-License-Identifier: Apache-2.0
// Copyright 2022 Enjinstarter
pragma solidity ^0.8.0;

/**
 * @title UnitConverter
 * @author Tim Loh
 * @notice Converts given amount between Wei and number of decimal places
 */
library UnitConverter {
    uint256 public constant TOKEN_MAX_DECIMALS = 18;

    /**
     * @notice Scale down given amount in Wei to given number of decimal places
     * @param weiAmount Amount in Wei
     * @param decimals Number of decimal places
     * @return decimalsAmount Amount in Wei scaled down to given number of decimal places
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function scaleWeiToDecimals(uint256 weiAmount, uint256 decimals)
        internal
        pure
        returns (uint256 decimalsAmount)
    {
        require(decimals <= TOKEN_MAX_DECIMALS, "UnitConverter: decimals");

        if (decimals < TOKEN_MAX_DECIMALS && weiAmount > 0) {
            uint256 decimalsDiff = TOKEN_MAX_DECIMALS - decimals;
            decimalsAmount = weiAmount / 10**decimalsDiff;
        } else {
            decimalsAmount = weiAmount;
        }
    }

    /**
     * @notice Scale up given amount in given number of decimal places to Wei
     * @param decimalsAmount Amount in number of decimal places
     * @param decimals Number of decimal places
     * @return weiAmount Amount in given number of decimal places scaled up to Wei
     */
    // https://github.com/crytic/slither/wiki/Detector-Documentation#dead-code
    // slither-disable-next-line dead-code
    function scaleDecimalsToWei(uint256 decimalsAmount, uint256 decimals)
        internal
        pure
        returns (uint256 weiAmount)
    {
        require(decimals <= TOKEN_MAX_DECIMALS, "UnitConverter: decimals");

        if (decimals < TOKEN_MAX_DECIMALS && decimalsAmount > 0) {
            uint256 decimalsDiff = TOKEN_MAX_DECIMALS - decimals;
            weiAmount = decimalsAmount * 10**decimalsDiff;
        } else {
            weiAmount = decimalsAmount;
        }
    }
}