// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

interface ICurvePool {
	function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
}