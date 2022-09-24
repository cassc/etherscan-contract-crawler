// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

// Solmate
import { ERC20 } from 'solmate/tokens/ERC20.sol';
import { Authority } from 'solmate/auth/Auth.sol';

// Custom
import { BurnableBEP20 } from './lib/BurnableBEP20.sol';
import { MintableBEP20 } from './lib/MintableBEP20.sol';

contract Powder is BurnableBEP20, MintableBEP20 {
	constructor(
		string memory _name,
		string memory _symbol,
		address _owner,
		Authority _authority
	) ERC20(_name, _symbol, 0) MintableBEP20(_owner, _authority) {}
}