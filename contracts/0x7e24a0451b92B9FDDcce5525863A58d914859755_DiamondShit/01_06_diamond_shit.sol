// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract DiamondShit is ERC20 {
    constructor() ERC20("Diamond Shit", "DSH") {
        _mint(msg.sender, 1000000000000 * 10 ** 18);
    }
}