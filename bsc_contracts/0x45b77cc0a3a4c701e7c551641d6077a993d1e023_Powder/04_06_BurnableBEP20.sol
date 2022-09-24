// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Custom
import { BEP20 } from './BEP20.sol';

abstract contract BurnableBEP20 is BEP20 {
	function burnFrom(address from, uint256 amount) public {
		uint256 allowed = allowance[from][msg.sender];

		if (allowed != type(uint256).max) {
			allowance[from][msg.sender] = allowed - amount;
		}

		_burn(from, amount);
	}

	function burn(uint256 amount) public {
		_burn(msg.sender, amount);
	}
}