// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";

contract NewsToken is ERC20, ERC20Burnable {
    constructor() ERC20("NewsToken", "NEWS") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}