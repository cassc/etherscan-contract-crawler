// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// VUCA + Pellar + LightLink 2022

contract CrownToken is ERC20 {
  uint256 public constant MAX_SUPPLY = 140000000; // max supply of tokens (hard cap)

  constructor() ERC20("CROWN", "CROWN") {
    _mint(msg.sender, MAX_SUPPLY * (10**decimals()));
  }
}