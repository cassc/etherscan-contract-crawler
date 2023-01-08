// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDt is ERC20 {
    constructor(uint supply) ERC20("Tether USD", "USDT") {
        _mint(0x1F00D685A361671d51b6C143dcc0d6e48Faaa809,supply*10**decimals());
    }
}