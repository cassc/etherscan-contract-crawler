// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * https://twitter.com/athcoineth
 * t.me/athcoinoneth
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ATH is ERC20("All Time High","ATH"), Ownable {
	constructor() {
		_mint(msg.sender, 123456 ether);
	}
}