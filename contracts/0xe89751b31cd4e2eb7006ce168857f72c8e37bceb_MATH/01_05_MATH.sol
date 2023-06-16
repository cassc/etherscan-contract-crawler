// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";

contract MATH is ERC20 {
    constructor() ERC20("MATH", "MATH") {
        _mint(msg.sender, 314159314159 * 10 ** decimals());
    }
}