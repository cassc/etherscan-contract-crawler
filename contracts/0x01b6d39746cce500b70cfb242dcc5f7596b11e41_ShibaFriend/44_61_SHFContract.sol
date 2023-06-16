// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SHFContract is ERC20 {
    uint8 private _decimals = 9;

    constructor() ERC20("SHIBAFRIEND", "SHFContract") {
    	_mint(msg.sender, 100000000000  * 10**9);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}