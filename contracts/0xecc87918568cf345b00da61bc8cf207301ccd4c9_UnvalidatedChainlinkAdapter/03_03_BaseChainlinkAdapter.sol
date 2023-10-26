// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AggregatorV3Interface} from "../../../interfaces/AggregatorV3Interface.sol";

/// @title ChainlinkAdapter Contract
/// @author Radiant
abstract contract BaseChainlinkAdapter is AggregatorV3Interface {
	/// @notice Token price feed
	AggregatorV3Interface public immutable chainlinkFeed;
	uint256 public immutable heartbeat;
	/// @notice How late since heartbeat before a price reverts
	uint256 public constant HEART_BEAT_TOLERANCE = 300;

	error AddressZero();
	error RoundNotComplete();
	error StalePrice();
	error InvalidPrice();

	/**
	 * @notice constructor
	 * @param _chainlinkFeed Chainlink price feed for token.
	 * @param _heartbeat heartbeat for feed
	 */
	constructor(address _chainlinkFeed, uint256 _heartbeat) {
		if (_chainlinkFeed == address(0)) revert AddressZero();
		chainlinkFeed = AggregatorV3Interface(_chainlinkFeed);
		heartbeat = _heartbeat;
	}

	/**
	 * @notice Returns USD price in quote token.
	 * @dev supports 18 decimal token
	 * @return price of token in decimal 8
	 */
	function latestAnswer() external view virtual returns (uint256 price);

	function validate(int256 _answer, uint256 _updatedAt) public view {
		if (_updatedAt == 0) revert RoundNotComplete();
		if (heartbeat > 0 && block.timestamp - _updatedAt >= heartbeat + HEART_BEAT_TOLERANCE) revert StalePrice();
		if (_answer <= 0) revert InvalidPrice();
	}

	/**
	 * @notice Returns version of chainlink price feed for token
	 */
	function version() external view returns (uint256) {
		return chainlinkFeed.version();
	}

	/**
	 * @notice Returns decimals of chainlink price feed for token
	 */
	function decimals() external view returns (uint8) {
		return chainlinkFeed.decimals();
	}

	/**
	 * @notice Returns description of chainlink price feed for token
	 */
	function description() external view returns (string memory) {
		return chainlinkFeed.description();
	}

	/**
	 * @notice Get data about a round
	 * @param _roundId the requested round ID
	 * @return roundId is the round ID from the aggregator for which the data was retrieved.
	 * @return answer is the answer for the given round
	 * @return startedAt is the timestamp when the round was started.
	 * @return updatedAt is the timestamp when the round last was updated.
	 * @return answeredInRound is the round ID of the round in which the answer was computed.
	 */
	function getRoundData(
		uint80 _roundId
	)
		external
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		(roundId, answer, startedAt, updatedAt, answeredInRound) = chainlinkFeed.getRoundData(_roundId);
	}

	/**
	 * @notice Returns data of latest round
	 * @return roundId is the round ID from the aggregator for which the data was retrieved.
	 * @return answer is the answer for the given round
	 * @return startedAt is the timestamp when the round was started.
	 * @return updatedAt is the timestamp when the round last was updated.
	 * @return answeredInRound is the round ID of the round in which the answer was computed.
	 */
	function latestRoundData()
		public
		view
		returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)
	{
		(roundId, answer, startedAt, updatedAt, answeredInRound) = chainlinkFeed.latestRoundData();
	}
}