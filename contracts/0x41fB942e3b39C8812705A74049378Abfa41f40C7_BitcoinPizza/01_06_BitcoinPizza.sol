// SPDX-License-Identifier: MIT


import "@openzeppelin/[email protected]/token/ERC20/ERC20.sol";
import "@openzeppelin/[email protected]/access/Ownable.sol";

pragma solidity ^0.8.0;


contract BitcoinPizza is Ownable, ERC20 {
    constructor() ERC20("Bitcoin Pizza", "PIZZA"){
        _mint(msg.sender,  420000000000000 * 10 ** decimals());  
    }
}