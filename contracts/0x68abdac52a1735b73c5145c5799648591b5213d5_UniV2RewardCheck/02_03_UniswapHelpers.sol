// SPDX-License-Identifier: UNLICENSED
// Created by DegenLabs https://bondswap.org

pragma solidity ^0.8.19;

library UniswapHelpers {
	// given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
	function getAmountOut(
		uint256 amountIn,
		uint256 reserveIn,
		uint256 reserveOut
	) internal pure returns (uint256 amountOut) {
		require(amountIn > 0, "Bond: INSUFFICIENT_INPUT_AMOUNT");
		require(reserveIn > 0 && reserveOut > 0, "Bond: INSUFFICIENT_LIQUIDITY");
		uint256 amountInWithFee = amountIn * 997;
		uint256 numerator = amountInWithFee * reserveOut;
		uint256 denominator = reserveIn * 1000 + amountInWithFee;
		amountOut = numerator / denominator;
	}

	// given an output amount of an asset and pair reserves, returns a required input amount of the other asset
	function getAmountIn(
		uint256 amountOut,
		uint256 reserveIn,
		uint256 reserveOut
	) internal pure returns (uint256 amountIn) {
		require(amountOut > 0, "Bond: INSUFFICIENT_OUTPUT_AMOUNT");
		require(reserveIn > 0 && reserveOut > 0, "Bond: INSUFFICIENT_LIQUIDITY");
		uint256 numerator = reserveIn * amountOut * 1000;
		uint256 denominator = (reserveOut - amountOut) * 997;
		amountIn = (numerator / denominator) + 1;
	}
}