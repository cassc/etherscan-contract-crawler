// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.8;


library Percentages {
	function from(uint32 val) internal pure returns (uint256) {
		require(val <= 10000, "Percentages: out of bounds");
		return val;
	}

	function times(uint256 p, uint256 val) internal pure returns (uint256) {
		return val * p / 10000;
	}
}