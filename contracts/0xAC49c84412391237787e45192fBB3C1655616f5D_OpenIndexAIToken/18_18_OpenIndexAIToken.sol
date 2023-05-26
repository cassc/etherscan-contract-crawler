// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @custom:security-contact [email protected]
contract OpenIndexAIToken is ERC20, ERC20Burnable, Ownable, ERC20Permit {
  constructor() ERC20("OpenIndexAI", "OIAI") ERC20Permit("OpenIndexAI") {
    _mint(msg.sender, 1_000_000_000 * (10**decimals()));
  }
}