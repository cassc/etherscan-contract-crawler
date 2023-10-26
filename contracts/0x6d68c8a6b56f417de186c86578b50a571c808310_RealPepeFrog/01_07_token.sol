// SPDX-License-Identifier: MIT
// https://twitter.com/Real_Pepe_Frog https://t.me/RealPepeFrogEntry https://realpepefrog.com	
pragma solidity ^0.8.19;

import "./@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./@openzeppelin/contracts/access/Ownable.sol";

contract RealPepeFrog is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Real Pepe Frog", unicode"лягушка") {
        _mint(msg.sender,  100000000 * (10 ** decimals())); 
    }
}