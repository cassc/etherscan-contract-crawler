// SPDX-License-Identifier: MIT


pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Yacc is ERC20 {
    address private linda = 0xaaa9dEDbb0Af25fa2624e73B78D2E6F63258Be60;
    constructor() ERC20("YACC", "YACC") {
        _mint(msg.sender, 2000000000000 * 10 ** decimals());
    }
}

