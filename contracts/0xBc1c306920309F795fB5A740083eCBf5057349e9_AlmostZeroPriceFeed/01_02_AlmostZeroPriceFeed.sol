// SPDX-License-Identifier: BUSL-1.1
// Gearbox Protocol. Generalized leverage for DeFi protocols
// (c) Gearbox Holdings, 2021
pragma solidity ^0.7.4;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

/// @title AlmostZeroPriceFeed pricefeed adapter
contract AlmostZeroPriceFeed is AggregatorV3Interface {
    function decimals() external view override returns (uint8) {
        return 18;
    }

    function description() external view override returns (string memory) {
        return "ZERO (one) priceFeed";
    }

    function version() external view override returns (uint256) {
        return 1;
    }

    function getRoundData(uint80)
        external
        pure
        override
        returns (
            uint80, // roundId,
            int256, // answer,
            uint256, // startedAt,
            uint256, // updatedAt,
            uint80 // answeredInRound
        )
    {
        revert("Function is not supported");
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        roundId = 1;
        answer = 100;
        startedAt = block.timestamp;
        updatedAt = block.timestamp;
        answeredInRound = 1;
    }
}