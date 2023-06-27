// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract MushroomKingdom is ERC20 {
    constructor() ERC20("Mushroom Kingdom", "TOAD") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
    }
}