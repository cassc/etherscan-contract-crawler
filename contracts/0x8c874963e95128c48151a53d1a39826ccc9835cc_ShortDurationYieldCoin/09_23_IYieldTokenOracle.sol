// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAggregatorV3} from "./IAggregatorV3.sol";

interface IYieldTokenOracle is IAggregatorV3 {
    function getRoundDetails(uint80)
        external
        view
        returns (uint80 roundId, uint256 balance, uint256 interest, uint256 totalSupply, uint256 updatedAt);

    function latestRoundDetails()
        external
        view
        returns (uint80 roundId, uint256 balance, uint256 interest, uint256 totalSupply, uint256 updatedAt);
}