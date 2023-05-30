// SPDX-License-Identifier: MIT LICENSE

// ALL CHANGES DONE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SALMON is ERC20, Ownable {

  
  mapping(address => bool) controllers;        // a mapping from an address to whether or not it can mint / burn
  constructor() ERC20("SALMON", "SALMON") { }

  // mints $SALMON to a recipient
  function mint(address to, uint256 amount) external {                    
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  // burns $SALMON from a holder
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }


  // enables an address to mint / burn
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  // disables an address from minting / burning
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}