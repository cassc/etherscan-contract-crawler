// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ERC20.sol";

contract BETADOGE is ERC20 {
    constructor() ERC20("BETADOGE", "BETADOGE") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}