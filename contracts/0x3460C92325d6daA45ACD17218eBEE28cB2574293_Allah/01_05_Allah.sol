// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Allah is ERC20 {
    constructor() ERC20("AlHamdullilah", "ALLAH") {
        _mint(msg.sender, 604191919191000000000000000000);
    }
}