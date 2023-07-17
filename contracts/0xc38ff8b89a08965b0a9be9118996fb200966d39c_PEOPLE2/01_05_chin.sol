// SPDX-License-Identifier: MIT
/*
    Telegram: https://t.me/PEOPLE2ETH
*/
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PEOPLE2 is ERC20 {
    constructor() ERC20("https://t.me/PEOPLE2ETH", "PEOPLE2.0") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}