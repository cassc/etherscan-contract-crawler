// contracts/WikiMoon.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WikiMoon is ERC20 {
    constructor(uint256 initialSupply) ERC20("Wiki Moon", "WikiM") {
        _mint(msg.sender, initialSupply);
    }
}