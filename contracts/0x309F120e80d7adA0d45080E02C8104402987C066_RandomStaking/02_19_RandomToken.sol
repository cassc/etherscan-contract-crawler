// SPDX-License-Identifier: MIT LICENSE
pragma solidity 0.8;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract RandomToken is ERC20, ERC20Burnable, Ownable {
  mapping(address => bool) controllers;

  constructor() ERC20("Randoms Token", "RNDMS") { }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "You are not a contract executor");
    _mint(to, amount);
  }
  //s
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