// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./ERC20.sol";

contract Pizza is ERC20, ReentrancyGuard {
    constructor() ERC20("Pizza", "PIZZA") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}