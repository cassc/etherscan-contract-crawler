// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract Campfire is ERC20 {
    constructor() ERC20("Campfire", "SITE") {
        _mint(msg.sender, 125000000000 * 10 ** decimals());
    }
}