// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Cure is ERC20 {
  constructor(string memory name, string memory symbol, uint initialSupply) ERC20(name, symbol) {
    _mint(msg.sender, initialSupply);
  }

  /**
   * @dev Burnable
   */
  function burn(uint amount) public {
    _burn(msg.sender, amount);
  }
}