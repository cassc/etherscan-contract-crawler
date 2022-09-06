// SPDX-License-Identifier: MIT LICENSE
/*

  /$$$$$$  /$$$$$$$  /$$   /$$ /$$$$$$$$
 /$$__  $$| $$__  $$| $$  /$$/|_____ $$ 
| $$  \__/| $$  \ $$| $$ /$$/      /$$/ 
| $$      | $$$$$$$/| $$$$$/      /$$/  
| $$      | $$__  $$| $$  $$     /$$/   
| $$    $$| $$  \ $$| $$\  $$   /$$/    
|  $$$$$$/| $$  | $$| $$ \  $$ /$$$$$$$$
 \______/ |__/  |__/|__/  \__/|________/
                                        
                                        
CRKZ Utility Token Contract for the Crookz Eco-System - by RION Labs

*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract CRKZ is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;
  
  constructor() ERC20("CRKZ Token", "CRKZ") {  
   _mint(msg.sender, 250000 ether);
  }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }
      else {
          super.burnFrom(account, amount);
      }
  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}