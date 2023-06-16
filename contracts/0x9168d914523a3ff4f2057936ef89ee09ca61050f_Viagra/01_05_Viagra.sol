// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

contract Viagra is ERC20 {
    constructor() ERC20("VIAGRA", "VIAGRA") {
        _mint(msg.sender, 1_000_000_000_000e18);
    }
}