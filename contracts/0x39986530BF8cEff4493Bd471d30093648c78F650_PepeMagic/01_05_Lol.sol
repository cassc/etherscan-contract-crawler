// SPDX-License-Identifier: MIT
// https://t.me/TooTurnt

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PepeMagic is ERC20 {
    constructor() ERC20("PePe Magic", "MPEP") {
        _mint(msg.sender, 100000 * 10**18);
    }
}