// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PEPE is ERC20 {
    constructor() ERC20(unicode"PEPE", unicode"Pepe Again, Again & Again") {
        uint256 tokenSupply = 420690000000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}