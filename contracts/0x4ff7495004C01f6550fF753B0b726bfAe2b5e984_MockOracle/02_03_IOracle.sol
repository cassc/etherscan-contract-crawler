// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice The Oracles' interface
 * @dev All `one-oracle` price providers, aggregator and oracle contracts implement this
 */
interface IOracle {
    /**
     * @notice Get USD (or equivalent) price of an asset
     * @param token_ The address of asset
     * @return _priceInUsd The USD price
     */
    function getPriceInUsd(address token_) external view returns (uint256 _priceInUsd);
}