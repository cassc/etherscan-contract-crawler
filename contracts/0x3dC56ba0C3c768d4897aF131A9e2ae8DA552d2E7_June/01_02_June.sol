// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC20} from "solmate/tokens/ERC20.sol";

contract June is ERC20 {
    constructor() ERC20("June", "JUNE", 18) {
        _mint(msg.sender, 1000000000 ether);
    }
}