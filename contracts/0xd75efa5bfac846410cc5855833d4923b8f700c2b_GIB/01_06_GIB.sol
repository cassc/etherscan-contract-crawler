// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@oz/token/ERC20/ERC20.sol";

contract GIB is ERC20 {
    constructor() ERC20("GIB", "GIB") {
        _mint(msg.sender, 1_000_000_000_000_000e18);
    }
}