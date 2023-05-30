// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPriceOracleManager {
    /**
     * Fetches the USD price for a token if required
     */
    function fetchPriceInUSD(address sourceToken) external;

    /**
     * Returns the price of the token in USD, normalized to the expected decimals param.
     */
    function getPriceInUSD(address token, uint256 expectedDecimals) external view returns (uint256);
}