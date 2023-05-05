// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TheGrimReaper is ERC20 {
    constructor() ERC20("The Grim Reaper", "REAPER") {
        _mint(msg.sender, 1000000000  * 10 ** 18);
    }
}