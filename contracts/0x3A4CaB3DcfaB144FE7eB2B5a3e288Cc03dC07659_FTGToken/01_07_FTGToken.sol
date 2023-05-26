// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FTGToken is Ownable, ERC20Burnable {
  string private constant _name = "fantomGO";
  string private constant _symbol = "FTG";

  constructor(uint256 initialSupply) ERC20(_name, _symbol) {
    _mint(owner(), initialSupply);
  }
}