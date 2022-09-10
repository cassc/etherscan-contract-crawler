// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPyth.sol";

abstract contract AbstractPyth is IPyth {
    /// @notice Returns the price feed with given id.
    /// @dev Reverts if the price does not exist.
    /// @param id The Pyth Price Feed ID of which to fetch the current price and confidence interval.
    function queryPriceFeed(bytes32 id) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    /// @notice Returns true if a price feed with the given id exists.
    /// @param id The Pyth Price Feed ID of which to check its existence.
    function priceFeedExists(bytes32 id) public view virtual returns (bool exists);

    /// @notice Returns the period (in seconds) that a price feed is considered valid since its publish time
    function getValidTimePeriod() public view virtual returns (uint validTimePeriod);

    function getCurrentPrice(bytes32 id) external view override returns (PythStructs.Price memory price) {
        uint64 publishTime;
        (price, publishTime) = getLatestAvailablePriceUnsafe(id);

        require(diff(block.timestamp, publishTime) <= getValidTimePeriod(), "current price unavailable");

        return price;
    }

    function getEmaPrice(bytes32 id) external view override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);

        price.price = priceFeed.emaPrice;
        price.conf = priceFeed.emaConf;
        price.expo = priceFeed.expo;
        return price;
    }

    function getLatestAvailablePriceUnsafe(bytes32 id) public view override returns (PythStructs.Price memory price, uint64 publishTime) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);

        price.expo = priceFeed.expo;
        if (priceFeed.status == PythStructs.PriceStatus.TRADING) {
            price.price = priceFeed.price;
            price.conf = priceFeed.conf;
            return (price, priceFeed.publishTime);
        }

        price.price = priceFeed.prevPrice;
        price.conf = priceFeed.prevConf;
        return (price, priceFeed.prevPublishTime);
    }

    function getLatestAvailablePriceWithinDuration(bytes32 id, uint64 duration) external view override returns (PythStructs.Price memory price) {
        uint64 publishTime;
        (price, publishTime) = getLatestAvailablePriceUnsafe(id);

        require(diff(block.timestamp, publishTime) <= duration, "No available price within given duration");

        return price;
    }

    function diff(uint x, uint y) internal pure returns (uint) {
        if (x > y) {
            return x - y;
        } else {
            return y - x;
        }
    }

    // Access modifier is overridden to public to be able to call it locally.
    function updatePriceFeeds(bytes[] calldata updateData) public virtual payable override;

    function updatePriceFeedsIfNecessary(bytes[] calldata updateData, bytes32[] calldata priceIds, uint64[] calldata publishTimes) external payable override {
        require(priceIds.length == publishTimes.length, "priceIds and publishTimes arrays should have same length");

        bool updateNeeded = false;
        for(uint i = 0; i < priceIds.length; i++) {
            if (!priceFeedExists(priceIds[i]) || queryPriceFeed(priceIds[i]).publishTime < publishTimes[i]) {
                updateNeeded = true;
            }
        }

        require(updateNeeded, "no prices in the submitted batch have fresh prices, so this update will have no effect");

        updatePriceFeeds(updateData);
    }
}