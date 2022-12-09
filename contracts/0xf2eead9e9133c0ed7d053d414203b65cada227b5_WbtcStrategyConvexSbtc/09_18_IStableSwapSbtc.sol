//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://etherscan.io/address/0x7fC77b5c7614E1533320Ea6DDc2Eb61fa00A9714#code

interface IStableSwapSbtc {
	function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount) external;

	function remove_liquidity_one_coin(
		uint256 amount,
		int128 i,
		uint256 min_amount
	) external;

	function get_virtual_price() external view returns (uint256);
}