// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RockShare is ERC20, Ownable {

	using SafeMath for uint256;
	
	constructor() ERC20("RockShare", "ROCK") {
		_mint(msg.sender, 1000000 ether);	
	}

	function mint(address to, uint256 amount) public onlyOwner {
		_mint(to, amount);
	}

	function burn(address from, uint256 amount) public onlyOwner {
		_burn(from, amount);
	}
}