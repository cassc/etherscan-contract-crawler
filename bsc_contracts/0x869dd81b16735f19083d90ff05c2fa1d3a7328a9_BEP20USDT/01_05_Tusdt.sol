// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract BEP20USDT is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_,symbol_){
        _mint(msg.sender, 9999_9999_9999_9999_9999_9999 * 10 ** 18);
    }
}