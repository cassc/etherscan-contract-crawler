// SPDX-License-Identifier: MIT
// Telegram https://t.me/NinjaPepe_BSC
pragma solidity ^0.8.9;

import "./ERC20.sol";

contract NinjaPepe is ERC20 {

    constructor() ERC20("NinjaPepe", "NinjaPepe") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}