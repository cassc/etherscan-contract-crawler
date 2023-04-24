// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * twitter.com/bidencoineth
 * t.me/bidencoineth
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Biden is ERC20 {
	constructor(
		string memory name, 
		string memory symbol, 
		address receiver, 
		uint amount
	) 
		ERC20(name, symbol) 
	{
		_mint(receiver, amount);
	}
}