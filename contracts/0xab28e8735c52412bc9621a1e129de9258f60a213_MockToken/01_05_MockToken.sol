// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// this is a MOCK
contract MockToken is ERC20 {
	uint8 private decimals_;

	constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol) {
		decimals_ = _decimals;
	}

	function mint(address _to, uint256 _amount) public {
		_mint(_to, _amount);
	}

	function decimals() public view override returns (uint8) {
		return decimals_;
	}
}