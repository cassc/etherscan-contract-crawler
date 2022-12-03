// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IPriceFeed} from "../interfaces/IPriceFeed.sol";
import {IOracle} from "../interfaces/IOracle.sol";
import {IUniswapV2Pair} from "../interfaces/IUniswapV2Pair.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        returns (
            // view
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        returns (
            // view
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

/**
 * A chainlink v3 aggregator port for the ARTH GMU oracle. It gives the ARTH price in USD terms.
 */
contract GMUUSDAggregatorV3 is AggregatorV3Interface {
    using SafeMath for uint256;
    IPriceFeed public gmuFeed;

    constructor(IPriceFeed _gmuFeed) {
        gmuFeed = _gmuFeed;
    }

    function decimals() external view override returns (uint8) {
        return uint8(gmuFeed.getDecimalPercision());
    }

    function description() external pure override returns (string memory) {
        return
            "A chainlink v3 aggregator port for the ARTH GMU oracle. It gives the ARTH price in USD terms.";
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80 _roundId)
        external
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _roundId,
            int256(gmuFeed.fetchPrice()),
            0,
            block.timestamp,
            _roundId
        );
    }

    function latestRoundData()
        external
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (1, int256(gmuFeed.fetchPrice()), 0, block.timestamp, 1);
    }
}