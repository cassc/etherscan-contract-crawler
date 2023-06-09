// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// LightLink 2022

contract LightLink is ERC20 {
  constructor() ERC20("LightLink", "LL") {
    _mint(msg.sender, 1000000000 * (10**decimals()));
  }
}