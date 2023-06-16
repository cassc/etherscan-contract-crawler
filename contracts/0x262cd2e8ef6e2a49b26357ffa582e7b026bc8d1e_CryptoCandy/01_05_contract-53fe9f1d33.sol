// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";

contract CryptoCandy is ERC20 {
    constructor() ERC20("Crypto Candy", "CANDY") {
        _mint(msg.sender, 1000000000000 * 10 ** decimals());
    }
}