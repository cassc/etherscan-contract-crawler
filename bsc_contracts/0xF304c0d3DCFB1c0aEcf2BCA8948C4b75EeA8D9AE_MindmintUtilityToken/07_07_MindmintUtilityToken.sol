// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * Utility Token
*/

contract MindmintUtilityToken is ERC20, ERC20Burnable, Ownable {
  constructor() ERC20('Mindmint Utility', 'MMT') {}

  function mint(address to, uint256 amount) public onlyOwner {
    _mint(to, amount);
  }
}