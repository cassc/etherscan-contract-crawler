// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MercyDAO is ERC20 {
    constructor() ERC20("MercyDAO", "MERCY") {
        _mint(msg.sender, 1000000000 * 10 ** decimals());
    }
}