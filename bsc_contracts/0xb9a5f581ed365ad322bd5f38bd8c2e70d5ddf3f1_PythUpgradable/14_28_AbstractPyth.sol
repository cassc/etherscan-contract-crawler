// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

import "./PythStructs.sol";
import "./IPyth.sol";

abstract contract AbstractPyth is IPyth {
    /// @notice Returns the price feed with given id.
    /// @dev Reverts if the price does not exist.
    /// @param id The Pyth Price Feed ID of which to fetch the PriceFeed.
    function queryPriceFeed(bytes32 id) public view virtual returns (PythStructs.PriceFeed memory priceFeed);

    /// @notice Returns true if a price feed with the given id exists.
    /// @param id The Pyth Price Feed ID of which to check its existence.
    function priceFeedExists(bytes32 id) public view virtual returns (bool exists);

    function getValidTimePeriod() public view virtual override returns (uint validTimePeriod);

    function getPrice(bytes32 id) external view override returns (PythStructs.Price memory price) {
        return getPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getEmaPrice(bytes32 id) external view override returns (PythStructs.Price memory price) {
        return getEmaPriceNoOlderThan(id, getValidTimePeriod());
    }

    function getPriceUnsafe(bytes32 id) public view override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.price;
    }

    function getPriceNoOlderThan(bytes32 id, uint age) public view override returns (PythStructs.Price memory price) {
        price = getPriceUnsafe(id);

        require(diff(block.timestamp, price.publishTime) <= age, "no price available which is recent enough");

        return price;
    }

    function getEmaPriceUnsafe(bytes32 id) public view override returns (PythStructs.Price memory price) {
        PythStructs.PriceFeed memory priceFeed = queryPriceFeed(id);
        return priceFeed.emaPrice;
    }

    function getEmaPriceNoOlderThan(bytes32 id, uint age) public view override returns (PythStructs.Price memory price) {
        price = getEmaPriceUnsafe(id);

        require(diff(block.timestamp, price.publishTime) <= age, "no ema price available which is recent enough");

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
            if (!priceFeedExists(priceIds[i]) || queryPriceFeed(priceIds[i]).price.publishTime < publishTimes[i]) {
                updateNeeded = true;
                break;
            }
        }

        require(updateNeeded, "no prices in the submitted batch have fresh prices, so this update will have no effect");

        updatePriceFeeds(updateData);
    }
}