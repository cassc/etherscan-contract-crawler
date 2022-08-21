// SPDX-License-Identifier: MIT

// As we all know, Celcius Network was a complete disaster. This is why fahrenheit has always been the superior burger degree of temperature. 
// Thank you Daniel Gabriel Fahrenheit and fuck you Anders Celsius and Alex Mashinsky

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SimpleToken is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint256 totalSupply_
    ) ERC20(name, symbol) {
        _mint(msg.sender, totalSupply_);
    }
}