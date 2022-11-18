// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.9.0;

/**
 *  @title Controls the transition and execution of liquidity deployment cycles.
 *  Accepts instructions that can move assets from the Pools to the Exchanges
 *  and back. Can also move assets to the treasury when appropriate.
 */
interface IManager {
	///@notice Gets current starting block
	///@return uint256 with block number
	function getCurrentCycle() external view returns (uint256);

	///@notice Gets current cycle index
	///@return uint256 current cycle number
	function getCurrentCycleIndex() external view returns (uint256);

	///@notice Gets cycle rollover status, true for rolling false for not
	///@return Bool representing whether cycle is rolling over or not
	function getRolloverStatus() external view returns (bool);
}