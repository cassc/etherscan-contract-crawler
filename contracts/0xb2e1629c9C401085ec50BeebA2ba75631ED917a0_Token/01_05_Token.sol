// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol';
import { ERC20 } from '../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Token is ERC20 {
	string public version;
  address public owner;

	uint8 private _decimals;

  // Модификатор доступа владельца
  modifier OnlyOwner() {
    require(owner == msg.sender, 'Permission denied: Owner');
    _;
  }

	constructor() ERC20('Jeembo Finance Token', 'JMBO') {
    _decimals = 6;
		version = '1.0';
    owner = msg.sender;
  }

  // Сменить владельца
  function _changeOwner(address newOwner) public OnlyOwner {
    owner = newOwner;
  }

  function __mint(address recipient, uint256 amount) public OnlyOwner {
    _mint(recipient, amount);
  }

	function decimals() public view override returns (uint8) {
    return _decimals;
  }
}