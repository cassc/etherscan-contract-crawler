// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/presets/ERC20PresetMinterPauser.sol";

contract Token is ERC20PresetMinterPauser {
    constructor(string memory name, string memory symbol, uint8 decimals, uint256 initialSupply) public
    	ERC20PresetMinterPauser(name, symbol) {
        	_setupDecimals(decimals);

        	if (initialSupply > 0) {
        		_mint(msg.sender, initialSupply);
        	}
    }
}