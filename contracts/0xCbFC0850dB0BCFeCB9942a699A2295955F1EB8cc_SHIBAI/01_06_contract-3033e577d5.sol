// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

contract SHIBAI is ERC20, Ownable {
    constructor() ERC20("SHIB AI", "SAI") {
        _mint(msg.sender, 10000 * 10 ** decimals());
    }
}