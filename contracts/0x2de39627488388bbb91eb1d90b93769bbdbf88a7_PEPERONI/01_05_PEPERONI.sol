// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PEPERONI is ERC20 {
    constructor() ERC20("PEPERONI", "PEPERONI") {
        _mint(msg.sender, 69420000000000 * 10 ** decimals());
    }
}