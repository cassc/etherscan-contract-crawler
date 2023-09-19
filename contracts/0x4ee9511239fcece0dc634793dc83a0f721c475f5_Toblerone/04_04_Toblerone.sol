// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Toblerone is ERC20 {
    constructor() ERC20("Toblerone", "TOBL") {
        _mint(msg.sender, 10000000 * 10 ** decimals());
    }
}