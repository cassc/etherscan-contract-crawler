// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./extensions/ERC20Burnable.sol";
import "./extensions/draft-ERC20Permit.sol";
import "./utils/TokenRecover.sol";


contract BitBase is ERC20, ERC20Burnable, ERC20Permit, TokenRecover {
    constructor() ERC20("BitBase", "BTBS") ERC20Permit("BitBase") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}