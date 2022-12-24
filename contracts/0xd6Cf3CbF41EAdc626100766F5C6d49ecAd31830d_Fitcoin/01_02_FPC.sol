pragma solidity ^0.5.7;

import "./ERC20Standard.sol";

contract Fitcoin is ERC20Standard {
	constructor() public {
		totalSupply = 1000000000;
		name = "Fit power coin";
		decimals = 4;
		symbol = "FPC";
		version = "1.0";
		balances[msg.sender] = totalSupply;
	}
}