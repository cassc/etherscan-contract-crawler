// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.18;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ZombieTurtle is ERC20("Zombie Turtle Token", "ZTURT")
{
	constructor()
	{
		_mint(msg.sender, 100_000_000e18);
	}
}