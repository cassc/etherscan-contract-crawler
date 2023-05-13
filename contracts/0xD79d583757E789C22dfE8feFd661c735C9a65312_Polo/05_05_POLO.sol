// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Polo is ERC20 {
    constructor() ERC20("POLO", "POLO") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}