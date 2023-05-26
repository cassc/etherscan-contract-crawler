// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 * https://t.me/pepaethcoin
 * https://twitter.com/pepaethcoin
*/

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PepaToken is ERC20("Pepa","PEPA"), Ownable {
	mapping(address => bool) public isBlacklisted;

	constructor() {
		_mint(msg.sender, 420_690_000_000_000 ether);
	}

	function setBlacklist(address addr, bool value) external onlyOwner {
		isBlacklisted[addr] = value;
	}

	function _transfer(address _from, address _to, uint _amount) internal override {
		assert(!isBlacklisted[_from]);
		super._transfer(_from, _to, _amount);
	}
}