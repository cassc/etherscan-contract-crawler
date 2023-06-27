// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract TheAlt is ERC20 {
    constructor() ERC20("TheAlt", "ALT") {
        _mint(msg.sender, 100000000000 * 10 ** decimals());
    }
}