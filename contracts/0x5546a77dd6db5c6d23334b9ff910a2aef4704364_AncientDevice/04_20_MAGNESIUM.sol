// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./ERC20.sol";
import "./OwnableWithAdmin.sol";

contract MAGNESIUM is ERC20, OwnableWithAdmin {

  // a mapping from an address to whether or not it can mint / burn. Melange Labs contracts only
  mapping(address => bool) public controllers;
  
  constructor() ERC20("MAGNESIUM", "MAG") { } 

  /**
   * mints $MAG to a recipient
   * @param to - the recipient of the $MAG
   * @param amount - the amount of $MAG to mint
   */
  function mint(address to, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can mint");
    _mint(to, amount);
  }

  /**
   * burns $MAG from a holder
   * @param from the holder of the $MAG
   * @param amount the amount of $MAG to burn
   */
  function burn(address from, uint256 amount) external {
    require(controllers[msg.sender], "Only controllers can burn");
    _burn(from, amount);
  }

  /**
   * enables an address to mint / burn (Melange Labs contracts only)
   * @param controller the address to enable
   */
  function addController(address controller) external onlyOwner {
    controllers[controller] = true;
  }

  /**
   * disables an address from minting / burning
   * @param controller the address to disable
   */
  function removeController(address controller) external onlyOwner {
    controllers[controller] = false;
  }
}