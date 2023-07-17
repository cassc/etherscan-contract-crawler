// SPDX-License-Identifier: MIT LICENSE
// Developed by Thanic® Tech Labs

pragma solidity 0.8.9;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract StoneParticles is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;
  
  constructor() ERC20("Stone Particles", "SP") { }

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

    function transfer(address to, uint tokens) onlyOwner public override returns (bool success) {
        require(controllers[msg.sender], "Only controllers can transfer");
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) onlyOwner public override returns (bool success) {
        require(controllers[msg.sender], "Only controllers can transfer");
        emit Transfer(from, to, tokens);
        return true;
    }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}