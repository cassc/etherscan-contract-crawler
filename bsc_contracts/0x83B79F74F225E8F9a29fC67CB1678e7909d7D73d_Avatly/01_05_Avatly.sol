// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC20.sol";

contract Avatly is ERC20 {
    constructor() ERC20("Avatly", "AVA") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}

