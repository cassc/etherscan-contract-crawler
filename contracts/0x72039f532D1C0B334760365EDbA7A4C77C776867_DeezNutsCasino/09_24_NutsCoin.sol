// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";
contract NutsCoin is ERC20, Ownable {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  uint256 public maxSupply = 6900000000 ether;
  // community wallet receives 690,000,000
  // development wallet reecives 69,000,000
  // total left for staking contract = 6141000000
  constructor() ERC20("NUTS", "NUTS") { }

  /**
   * mints $Deez to a recipient
   * @param to the recipient of the $Deez
   * @param amount the amount of $Deez to mint
   */
  function mint(address to, uint256 amount) external {
    require(totalSupply() + amount <= maxSupply, "Max supply of token reached");
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /**
   * burns $Deez from a holder
   * @param from the holder of the $Deez
   * @param amount the amount of $Deez to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}