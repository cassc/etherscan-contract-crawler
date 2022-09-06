// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

library HelperLib {
	uint256 constant FEE_SCALE = 1_000_000;

	function getFeeFraction(uint256 amount, uint256 fee)
		internal
		pure
		returns (uint256)
	{
		if (fee == 0) return 0;
		return (amount * fee) / FEE_SCALE;
	}
}