// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";

contract COPIUM is ERC20 {
    constructor() ERC20("COPIUM", "COPIUM") {
        _mint(msg.sender, 420690420690420 * 10 ** decimals());
    }
}