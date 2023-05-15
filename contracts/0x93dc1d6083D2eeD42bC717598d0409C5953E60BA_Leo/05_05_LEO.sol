// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Leo is ERC20 {
    constructor() ERC20("LEO", "LEO") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}