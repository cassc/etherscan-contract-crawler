// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Custom
import { BEP20 } from './BEP20.sol';

// Solmate
import { Auth, Authority } from 'solmate/auth/Auth.sol';

abstract contract MintableBEP20 is BEP20, Auth {
	constructor(address _owner, Authority _authority) Auth(_owner, _authority) {}

	function mint(address to, uint256 amount) public requiresAuth {
		_mint(to, amount);
	}

	function getOwner() external view override returns (address) {
		return owner;
	}
}