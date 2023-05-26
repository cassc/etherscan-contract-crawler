// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


pragma solidity ^0.8.19;


contract ThreeSToken is ERC20, ERC20Burnable {
    
    constructor(
        string memory name,
        string memory symbol,
        uint256 _totalSupply
    ) ERC20(name, symbol) {
        _mint(msg.sender, _totalSupply);
    }
}