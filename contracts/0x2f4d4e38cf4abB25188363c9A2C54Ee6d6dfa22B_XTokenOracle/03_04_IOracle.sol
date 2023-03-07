//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol';

interface IOracle is AggregatorInterface {
    function submit(uint256 roundId, int256 price) external;

    function decimals() external view returns (uint8);
}