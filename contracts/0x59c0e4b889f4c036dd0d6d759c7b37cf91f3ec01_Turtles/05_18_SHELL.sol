// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract SHELL is ERC20, Ownable, ReentrancyGuard {

  // a mapping from an address to whether or not it can mint / burn
  mapping(address => bool) treasureTurtles;

  constructor() ERC20("SHELL", "SHELL") { }

  /*
   * mints $SHELL to a recipient
   * @param to the recipient of the $SHELL
   * @param amount the amount of $SHELL to mint
   */
  function mint(address to, uint256 amount) external nonReentrant {
    require(treasureTurtles[msg.sender], "ONLY TREASURE TURTLES CAN MINT!");
    _mint(to, amount);
  }

  /*
   * burns $SHELL from a holder
   * @param from the holder of the $SHELL
   * @param amount the amount of $SHELL to burn
   */
  function burn(address from, uint256 amount) external nonReentrant {
    require(treasureTurtles[msg.sender], "ONLY TREASURE TURTLES CAN BURN!");
    _burn(from, amount);
  }

  /*
   * enables an address to mint / burn
   * @param _addresses the addresses to enable as Treasure Turtles
   */
  function addTreasureTurtles(address[] calldata _addresses) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length; i++) {
        treasureTurtles[_addresses[i]] = true;
    }
  }

  /*
   * disables an address from minting / burning
   * @param treasureTurtle the address to disbale
   */
  function removeTreasureTurtle(address _treasureTurtle) external onlyOwner {
    treasureTurtles[_treasureTurtle] = false;
  }
}