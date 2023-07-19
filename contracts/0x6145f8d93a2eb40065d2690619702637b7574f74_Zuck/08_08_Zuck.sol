// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

/*
    *Zuck is a cuck*

    *I propose a literal dick measuring contest*

*/

import "./ERC20.sol";

contract Zuck is ERC20Permit, ReentrancyGuard {
    constructor() ERC20Permit("ZuckCuck", "ZuckCuck") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}