// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IValioCustomAggregator {
    function description() external view returns (string memory);

    function decimals() external view returns (uint8);

    function latestRoundData(
        address asset
    ) external view returns (int256 answer, uint256 updatedAt);
}