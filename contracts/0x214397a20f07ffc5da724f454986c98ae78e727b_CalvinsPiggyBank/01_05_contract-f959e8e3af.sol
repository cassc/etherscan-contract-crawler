// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract CalvinsPiggyBank is ERC20 {
    constructor() ERC20("Calvin's Piggy Bank", "CALVIN") {
        _mint(0x9536A7d4b47e649F7ae7152334c8C06985dC0f30, 1000000000 * 10 ** decimals());
    }
}