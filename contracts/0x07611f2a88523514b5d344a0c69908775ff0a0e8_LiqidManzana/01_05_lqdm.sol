// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LiqidManzana is ERC20 {
    constructor() ERC20("Liqid Manzana", "LQDM") {
        uint256 totalSupply = 777000000 * 10 ** decimals();
        _mint(msg.sender, totalSupply);
    }
}