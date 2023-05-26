// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Sun is ERC20 {
    constructor() ERC20("Sun", "SUN") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}