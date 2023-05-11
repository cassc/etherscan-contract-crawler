// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

contract MartinLutherKing is ERC20, ERC20Burnable {
    constructor() ERC20("Martin Luther King", "MLK") {
        _mint(msg.sender, 12151929 * 10 ** decimals());
    }
}