// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * https://twitter.com/faggotcoineth
 * t.me/faggotcoineth
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Faggot is ERC20("FAGGOT","FAGGOT"), Ownable {
	constructor() {
		_mint(msg.sender, 10_000_000 ether);
	}
}