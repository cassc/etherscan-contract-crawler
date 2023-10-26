// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/[email protected]/token/ERC20/extensions/ERC20Permit.sol";

contract PyramidScam is ERC20, ERC20Burnable, ERC20Permit {
    constructor() ERC20("Pyramid Scam", "PS") ERC20Permit("Pyramid Scam") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}