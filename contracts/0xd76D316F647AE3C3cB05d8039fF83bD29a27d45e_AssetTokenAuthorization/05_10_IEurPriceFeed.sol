//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEurPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by any EurPriceFeed logic contract used in the protocol.
 *
 */
interface IEurPriceFeed {
    /**
     * @dev Gets the price a `_asset` in EUR.
     *
     * @param _asset address of asset to get the price.
     */
    function getPrice(address _asset) external returns (uint256);

    /**
     * @dev Gets how many EUR represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the price.
     * @param _amount amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _amount) external view returns (uint256);

    /**
     * @dev Sets feed addresses for a given group of assets.
     *
     * @param _assets Array of assets addresses.
     * @param _feeds Array of asset/ETH price feeds.
     */
    function setAssetsFeeds(
        address[] memory _assets,
        address[] memory _feeds,
        address[] memory _denominations
    ) external;

    /**
     * @dev Sets feed addresse for a given asset.
     *
     * @param _asset Assets address.
     * @param _feed Asset/ETH price feed.
     */
    function setAssetFeed(
        address _asset,
        address _feed,
        address _denomination
    ) external;
}