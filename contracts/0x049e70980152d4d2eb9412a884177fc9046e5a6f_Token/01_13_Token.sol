// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20, AccessControl {
    constructor(uint256 initialSupply) ERC20 ("Token","ERC20"){
        _mint(msg.sender, initialSupply*10**decimals());
    }
    function mint(address to, uint256 amount) public {
       _mint(to, amount); 
    } 
   
    }