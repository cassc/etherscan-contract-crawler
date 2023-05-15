// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "ERC20.sol";




contract Token is ERC20 {
    constructor() ERC20("AkbarAgha", "Befarma") {
        _mint(msg.sender, 100000000000 * 10 ** 18);
    }
}