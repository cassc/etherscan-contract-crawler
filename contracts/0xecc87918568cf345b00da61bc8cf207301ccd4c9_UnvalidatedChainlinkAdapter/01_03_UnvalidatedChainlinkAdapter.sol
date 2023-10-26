// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {AggregatorV3Interface} from "../../../interfaces/AggregatorV3Interface.sol";
import {BaseChainlinkAdapter} from "./BaseChainlinkAdapter.sol";

/// @title ChainlinkAdapter Contract
/// @author Radiant
contract UnvalidatedChainlinkAdapter is BaseChainlinkAdapter {
	constructor(address _chainlinkFeed, uint256 _heartbeat) BaseChainlinkAdapter(_chainlinkFeed, _heartbeat) {}

	/**
	 * @notice Returns USD price in quote token.
	 * @dev supports 18 decimal token
	 * @return price of token in decimal 8
	 */
	function latestAnswer() external view override returns (uint256 price) {
		(, int256 answer, , , ) = chainlinkFeed.latestRoundData();
		return uint256(answer);
	}
}