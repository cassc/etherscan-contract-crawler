// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract HashHaven is ERC20 {
    constructor() ERC20("HashHaven", "HSHH") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}
