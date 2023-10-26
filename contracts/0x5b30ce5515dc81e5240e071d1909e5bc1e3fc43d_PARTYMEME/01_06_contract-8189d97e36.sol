// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract PARTYMEME is ERC20 {
    constructor() ERC20("PARTYMEME", "PMEME") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}