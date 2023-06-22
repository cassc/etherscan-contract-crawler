//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol';

interface IDropsOracle {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}