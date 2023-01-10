// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";


contract GRF is ERC20, ERC20Burnable, Ownable {

  mapping(address => bool) controllers;
    uint256 constant MILLION = 1_000_000 * 10**uint256(18);
  uint256 constant MAX_SUPPLY = 40 * MILLION;
  constructor() ERC20("GRF", "$GRF") { }

  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    require(totalSupply() + amount <= MAX_SUPPLY,"Max supply exceeded!");
    _mint(to, amount);
  }

  function burnFrom(address account, uint256 amount) public override {
      if (controllers[msg.sender]) {
          _burn(account, amount);
      }

  }

  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}