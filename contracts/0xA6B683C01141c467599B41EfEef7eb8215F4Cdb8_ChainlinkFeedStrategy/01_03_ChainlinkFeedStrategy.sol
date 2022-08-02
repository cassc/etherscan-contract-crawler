// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./../IFeedStrategy.sol";
import "./../../../interfaces/IChainlinkPriceFeed.sol";

contract ChainlinkFeedStrategy is IFeedStrategy {
    IChainlinkPriceFeed public immutable chainlinkFeed;

    constructor(address chainlinkFeedAddress) {
        chainlinkFeed = IChainlinkPriceFeed(chainlinkFeedAddress);
    }

    function getPrice() external view returns (int256 value, uint8 decimals) {
        return (chainlinkFeed.latestAnswer(), chainlinkFeed.decimals());
    }
}