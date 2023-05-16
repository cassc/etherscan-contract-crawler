// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Jenga is ERC20 {
    constructor() ERC20("Jenga", "JENGA") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}