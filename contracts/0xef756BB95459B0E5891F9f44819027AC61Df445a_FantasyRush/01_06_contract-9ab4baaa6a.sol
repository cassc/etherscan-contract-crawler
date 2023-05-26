// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

contract FantasyRush is ERC20, ERC20Burnable {
    constructor() ERC20("FantasyRush", "RUSH") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}