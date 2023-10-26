// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IPriceConsumer {
    /**
     * Fetches the USD price for a token if required
     */
    function fetchPriceInUSD(address token, uint256 minTimestamp) external;

    /**
     * Returns the fetched price in USD, the number of decimals and the timestamp of the price
     */
    function getPriceInUSD(address token)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}