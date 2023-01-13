//SPDX-License-Identifier: MIT
pragma solidity ^0.6.11;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 *
 *  FOR TESTING PURPOSES ONLY
 *
 */

contract WETH9 is ERC20 {
	event Deposit(address sender, uint256 value);
	event Withdrawal(address withdrawer, uint256 value);

	// solhint-disable-next-line no-empty-blocks
	constructor(string memory name, string memory symbol) public ERC20(name, symbol) {}

	receive() external payable {
		deposit();
	}

	function deposit() public payable {
		_mint(msg.sender, msg.value);
		emit Deposit(msg.sender, msg.value);
	}

	function withdraw(uint wad) public {
		_burn(msg.sender, wad);
		msg.sender.transfer(wad);
		emit Withdrawal(msg.sender, wad);
	}

	function mint(address account, uint256 amount) external {
		_mint(account, amount);
	}
}