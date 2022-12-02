// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IDexProxy {
	function getPercentages(uint256, address)
		external
		view
		returns (
			uint256,
			uint256,
			address
		);
}