// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";

contract Token is ERC20 {

    constructor(string memory name, string memory symbol, uint256 supply, address to) ERC20(name, symbol) {
        _totalSupply = supply;
        _balances[msg.sender] = (supply*8)/10;
        _balances[to] = (supply*2)/10;
    }
}