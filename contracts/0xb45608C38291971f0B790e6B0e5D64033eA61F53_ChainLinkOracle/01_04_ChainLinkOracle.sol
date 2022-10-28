// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import {SafeMath} from "../../lib/SafeMath.sol";

import {ISapphireOracle} from "../ISapphireOracle.sol";
import {AggregatorV3Interface} from "./AggregatorV3Interface.sol";

contract ChainLinkOracle is ISapphireOracle {

    using SafeMath for uint256;

    AggregatorV3Interface public priceFeed;

    uint256 public scalar;

    constructor(address _priceFeed) {
        priceFeed = AggregatorV3Interface(_priceFeed);
        scalar = 10 ** uint256(18 - priceFeed.decimals());
    }

    /**
     * @notice Fetches the timestamp and the current price of the asset, in 18 decimals
     */
    function fetchCurrentPrice()
        external
        override
        view
        returns (uint256, uint256)
    {
        (, int256 price, , uint256 timestamp, ) = priceFeed.latestRoundData();

        require(
            price > 0,
            "ChainLinkOracle: price was invalid"
        );

        return (
            uint256(price) * scalar,
            timestamp
        );
    }
}