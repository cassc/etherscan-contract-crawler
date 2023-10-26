// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KEK2 is ERC20 {
    constructor() ERC20("KEK2", "Pepe Prophecy 2.0") {
        uint256 tokenSupply = 420690000000 * (10**decimals());
        _mint(msg.sender, tokenSupply);
    }
}