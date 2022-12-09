//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// https://etherscan.io/address/0xDC24316b9AE028F1497c275EB9192a3Ea0f67022#code

interface IStableSwapEth {
	function get_virtual_price() external view returns (uint256);

	function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount) external payable;

	function remove_liquidity_one_coin(
		uint256 token_amount,
		int128 i,
		uint256 min_amount
	) external;
}