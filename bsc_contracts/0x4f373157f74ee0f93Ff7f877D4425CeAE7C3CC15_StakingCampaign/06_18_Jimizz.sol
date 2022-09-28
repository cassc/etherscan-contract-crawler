// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "./EmergencyDrainable.sol";

/// @custom:security-contact [email protected]
contract Jimizz is ERC20, ERC20Burnable, ERC20Permit, EmergencyDrainable {
  constructor()
    ERC20("Jimizz", "JMZ")
    ERC20Permit("Jimizz")
    EmergencyDrainable(address(0x0))
  {
    _mint(msg.sender, 8000000000 * 10 ** decimals());
  }
}