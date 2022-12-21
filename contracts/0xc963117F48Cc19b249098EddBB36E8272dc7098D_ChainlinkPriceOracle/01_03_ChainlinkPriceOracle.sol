// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {IPriceOracle} from "./IPriceOracle.sol";

contract ChainlinkPriceOracle is IPriceOracle {
    uint256 constant priceInUSD = uint256(10 * 1e18) * 1e8;
    AggregatorV3Interface internal priceFeed;

    constructor(address _aggregator) {
        priceFeed = AggregatorV3Interface(_aggregator);
    }

    /**
     * @notice get latest price in ETH for $10
     */
    function getLatestPrice() public view returns (uint256) {
        (, int256 ethPriceInUsd, , , ) = priceFeed.latestRoundData();

        return uint256(ethPriceInUsd);
    }

    function getPriceInEth() external view override returns (uint256) {
        return priceInUSD / getLatestPrice();
    }
}