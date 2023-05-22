// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract Knight is ERC20 {

    constructor() ERC20("KNIGHT", "KNIGHT") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}