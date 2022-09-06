// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CMToken is ERC20, Ownable {
	constructor() ERC20("CheckMate Token", "CMT") {}

	function mint(uint256 amount, address to) public onlyOwner {
		_mint(to, amount);
	}
}