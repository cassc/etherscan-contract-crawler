// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WallStreetDaddy is ERC20, Ownable {
  constructor() ERC20("Wall Street Daddy", "WSD") {
    _mint(msg.sender, 69_000_000_000 * 1e18);
  }
}