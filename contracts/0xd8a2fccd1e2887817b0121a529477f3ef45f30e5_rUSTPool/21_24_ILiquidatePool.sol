// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ILiquidatePool {
	function liquidateSTBT(address caller, uint256 stbtAmount) external;

	function flashLiquidateSTBTByCurve(
		uint256 stbtAmount,
		int128 j,
		uint256 minReturn,
		address receiver
	) external;
}