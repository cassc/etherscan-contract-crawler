// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <0.9.0;

import "solmate/src/tokens/ERC20.sol";

contract BPX is ERC20 {
	/**
	 * string name name of token
	 * string symbol token symbol shown on etherscan/uniswap/etc
	 * address banker address to receive all initial supply
	 * uint totalSupply total number of tokens to create (ignoring decimals -
	 * those are calculated and total amount is math'd during construction)
	 */
	constructor(
		string memory name_,
		string memory symbol_,
		address banker_,
		uint256 totalSupply_,
		uint8 decimals_
	) ERC20(name_, symbol_, decimals_) {
		_mint(banker_, totalSupply_ * (10 ** decimals_));
	}
}