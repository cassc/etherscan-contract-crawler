// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract NFTEarth is ERC20 {
    constructor() ERC20("NFTEarth", "NFTE") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }
}