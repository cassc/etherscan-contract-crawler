// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract PERPAI is ERC20, Ownable {
    constructor() ERC20("PERP AI", "AIP") {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}