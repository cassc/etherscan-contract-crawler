// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);

    function getPriceNAV(address _assetOne, address _assetTwo) external view returns (uint256);

    function getCompoundExchangeRate(address _asset, address _finalAsset) external view returns (uint256);

}