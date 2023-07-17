// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract TheChosenOne is ERC20, Ownable {
    constructor() ERC20("The Chosen One", "MUSK") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
    
}

