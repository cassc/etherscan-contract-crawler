// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "../external/AggregatorV3Interface.sol";

contract PriceFeed is AggregatorV3Interface {
    constructor() {}

    function decimals() override external view returns (uint8) {
        return 8;
    }

    function description() override external view returns (string memory) {
        return 'DAI / BNB';
    }

    function latestRoundData() override external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (
            18446744073709572587,
            2737073543080504,
            1645801445,
            1645801445,
            18446744073709572587
        );
    }
}