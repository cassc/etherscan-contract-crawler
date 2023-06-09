// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Boo is ERC20, Ownable {
  
  bool controlled = true;

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) controllers;
  
  constructor() ERC20("Boo", "BOO") {}

  /**
   * mints $BOO to a recipient
   * @param to the recipient of the $BOO
   * @param amount the amount of $BOO to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "only controllers can mint");
    _mint(to, amount);
  }

  /**
   * burns $BOO from a holder
   * @param from the holder of the $BOO
   * @param amount the amount of $BOO to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "only controllers can burn");
    _burn(from, amount);
  }

  /**
   * enables an address to mint / burn
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    require(controlled, "can't add new controller");
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disbale
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }

  /**
   * permanently release control of the contract
   */
  function releaseControl() external onlyOwner {
      require(controlled, "control is already released");
      controlled = false;
  }

}