// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../libraries/BatchAuctionQ.sol";

contract TestBatchAuctionQ {
    using BatchAuctionQ for BatchAuctionQ.Queue;

    BatchAuctionQ.Queue internal queue;

    function isEmpty() public view returns (bool) {
        return queue.isEmpty();
    }

    function insert(address owner, int256 price, uint256 quantity) public {
        queue.insert(owner, price, quantity);
    }

    function remove(uint256 index) public {
        queue.remove(index);
    }

    function getBidPriceList() public view returns (int256[] memory) {
        return queue.bidPriceList;
    }

    function getBidQuantityList() public view returns (uint256[] memory) {
        return queue.bidQuantityList;
    }

    function getBidAddresses() public view returns (address[] memory) {
        return queue.bidOwnerList;
    }

    function getFills() public view returns (uint256[] memory) {
        return queue.filledAmount;
    }

    function computeFills(uint64 totalSize) public {
        queue.computeFills(totalSize);
    }

    function getClearingPrice() public view returns (int256) {
        return queue.clearingPrice;
    }
}