//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.7.0;

/**
 * @title IEurPriceFeedForSmtPriceFeed
 * @author Protofire
 * @dev Interface to be implemented by EurPriceFeed
 *
 */
interface IEurPriceFeedForSmtPriceFeed {
    /**
     * @dev Gets the return value digits
     */
    function RETURN_DIGITS_BASE18() external view returns (uint256);

    /**
     * @dev Gets the eurUsdFeed from EurPriceFeed
     */
    function eurUsdFeed() external view returns (address);

    /**
     * @dev Gets how many EUR represents the `_amount` of `_asset`.
     *
     * @param _asset address of asset to get the price.
     * @param _amount amount of `_asset`.
     */
    function calculateAmount(address _asset, uint256 _amount) external view returns (uint256);
}