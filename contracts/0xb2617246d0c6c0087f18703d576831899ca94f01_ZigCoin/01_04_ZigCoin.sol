// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import './ERC20.sol';

contract ZigCoin is ERC20 {

    constructor() ERC20("ZigCoin", "ZIG") {
        // Fix supply: 2.000.000.000 tokens
        _mint(msg.sender, 2000000000 * 10 ** 18);
    }
}