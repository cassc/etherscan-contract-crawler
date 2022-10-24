//SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import "./ERC20/ERC20.sol";

contract BZGToken is ERC20 {

    uint8 private _decimals = 18;
    uint256 private initSupply = 1000000000;

	constructor() ERC20("Bazinga Token","BZG") {
		_setupDecimals(_decimals);
	    _mint(msg.sender, initSupply * 10 ** _decimals);
	}
	
}