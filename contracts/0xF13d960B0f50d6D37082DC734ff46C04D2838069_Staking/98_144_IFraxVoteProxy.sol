// SPDX-License-Identifier: MIT
pragma solidity 0.6.11;

interface IFraxVoteProxy {
	// Current Frax booster address
	function operator() external returns (address);
}