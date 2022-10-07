// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <=0.8.2;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DirectMinimalErc20 is ERC20Burnable, Ownable {
	string public _name;
	string public _symbol;
	constructor() ERC20("", "") {
	}

	function init(address to, string memory name_, string memory symbol_, uint256 supply)
	external onlyOwner {
		require(bytes(_name).length == 0 && bytes(_symbol).length == 0 && totalSupply() == 0,
			"already initialized");
		_name = name_;
		_symbol = symbol_;
		_mint(to, supply);
	}

	function name() public override view returns (string memory) {
		return _name;
	}

	function symbol() public override view returns (string memory) {
		return _symbol;
	}
}