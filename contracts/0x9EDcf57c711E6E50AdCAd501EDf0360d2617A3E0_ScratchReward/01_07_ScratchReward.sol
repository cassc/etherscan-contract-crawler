// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract ScratchReward is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;
  
  constructor() ERC20("scratch", "scra") { }

  uint256 _maxSupply = 5000000000 ether;

  function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require((totalSupply() + amount) <= _maxSupply, "Maximum supply has been reached");
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