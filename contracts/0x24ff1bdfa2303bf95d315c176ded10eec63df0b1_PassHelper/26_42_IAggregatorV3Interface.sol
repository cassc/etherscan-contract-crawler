// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IAggregatorV3Interface {
	function latestRoundData() external view
    returns (
		uint80 roundId,
		int256 answer,
		uint256 startedAt,
		uint256 updatedAt,
		uint80 answeredInRound
    );
}