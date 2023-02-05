// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { UintArrayLib } from "../../lib/array-lib/src/UintArrayLib.sol";

import "../libraries/Errors.sol";

/// @notice a special queue struct for auction mechanics
library BatchAuctionQ {
    struct Queue {
        int256 clearingPrice;
        ///@notice array of bid prices in time order
        int256[] bidPriceList;
        ///@notice array of bid quantities in time order
        uint256[] bidQuantityList;
        ///@notice array of bidders
        address[] bidOwnerList;
        ///@notice winning bids
        uint256[] filledAmount;
    }

    function isEmpty(Queue storage self) external view returns (bool) {
        return self.bidPriceList.length == 0;
    }

    ///@notice insert bid in heap
    function insert(Queue storage self, address owner, int256 price, uint256 quantity) external returns (uint256 index) {
        self.bidPriceList.push(price);
        self.bidQuantityList.push(quantity);
        self.bidOwnerList.push(owner);
        self.filledAmount.push(0);

        index = self.bidPriceList.length - 1;
    }

    /// @notice remove deletes the owner from the owner list, so checking for a 0 address checks that a bid was pulled
    function remove(Queue storage self, uint256 index) external {
        delete self.bidOwnerList[index];
        delete self.bidQuantityList[index];
        delete self.bidPriceList[index];
        delete self.filledAmount[index];
    }

    /**
     * @notice fills as many bids as possible at the highest price as possible, the lowest price bid that was filled should become the clearing price
     */
    function computeFills(Queue storage self, uint256 totalSize) external returns (uint256 totalFilled, int256 clearingPrice) {
        uint256 bidLength = self.bidQuantityList.length;

        if (bidLength == 0) return (0, 0);

        if (UintArrayLib.sum(self.bidQuantityList) == 0) return (0, 0);

        uint256 bidId;
        uint256 bidQuantity;
        uint256 orderFilled;
        uint256 lastFilledBidId;

        // sort the bids by price to return an array of indices
        uint256[] memory bidOrder = _argSort(self.bidPriceList);

        // start from back of list to reverse sort
        uint256 i = bidLength - 1;
        bool endOfBids = false;

        while (totalFilled < totalSize && !endOfBids) {
            bidId = bidOrder[i];

            endOfBids = i == 0;

            // decrease index here, do not use i after this
            unchecked {
                --i;
            }

            // if this bid was removed, skip it
            if (self.bidOwnerList[bidId] == address(0)) continue;

            bidQuantity = self.bidQuantityList[bidId];

            //check if we can only partly fill a bid
            if ((totalFilled + bidQuantity) > totalSize) {
                orderFilled = totalSize - totalFilled;
            } else {
                orderFilled = bidQuantity;
            }

            self.filledAmount[bidId] = orderFilled;

            totalFilled += orderFilled;

            lastFilledBidId = bidId;
        }

        self.clearingPrice = clearingPrice = self.bidPriceList[lastFilledBidId];
    }

    /**
     * @dev sort of an int256 array with bubble sort returning indices
     *      indices favore FIFO
     */
    function _argSort(int256[] memory arr) internal pure returns (uint256[] memory indices) {
        indices = new uint256[](arr.length);
        int256[] memory tmp = new int256[](arr.length);
        unchecked {
            uint256 i;
            for (i; i < arr.length; ++i) {
                indices[i] = i;
                tmp[i] = arr[i];
            }
            if (tmp.length <= 1) return indices;
            for (i = 0; i < tmp.length; ++i) {
                for (uint256 j = i + 1; j < tmp.length; ++j) {
                    if (tmp[i] >= tmp[j]) {
                        (tmp[i], tmp[j]) = (tmp[j], tmp[i]);
                        (indices[i], indices[j]) = (indices[j], indices[i]);
                    }
                }
            }
        }
    }
}