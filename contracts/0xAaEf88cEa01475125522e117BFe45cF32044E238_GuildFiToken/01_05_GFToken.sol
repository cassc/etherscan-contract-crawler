//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract GuildFiToken is ERC20("GuildFi Token", "GF") {
  constructor() {
    _mint(msg.sender, 1_000_000_000 ether);
  }
}