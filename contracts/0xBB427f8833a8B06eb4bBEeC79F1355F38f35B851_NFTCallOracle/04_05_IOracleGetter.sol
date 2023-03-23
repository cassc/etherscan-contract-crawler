// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title IOracleGetter interface
 * @notice Interface for the nft price oracle.
 **/

interface IOracleGetter {
    /**
     * @dev returns the asset price in ETH
     * @param asset the address of the asset
     * @return the ETH price of the asset
     **/
    function getAssetPrice(address asset) external view returns (uint256);

    /**
     * @dev returns the volatility of the asset
     * @param asset the address of the asset
     * @return the volatility of the asset
     **/
    function getAssetVol(address asset) external view returns (uint256);
}