// SPDX-License-Identifier: MIT
// https://t.me/TooTurnt

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TooTurntToken is ERC20 {
    constructor() ERC20("Too Turnt Token", "TURNT") {
        _mint(msg.sender, 69042000000000 * 10**18);
    }
}