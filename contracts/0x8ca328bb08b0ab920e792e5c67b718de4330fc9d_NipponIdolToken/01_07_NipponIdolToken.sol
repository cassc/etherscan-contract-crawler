// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Capped.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NipponIdolToken is Ownable, ERC20Capped {
  uint256 public constant CAP_AMOUNT = 1e9 * 1e18;

  constructor() ERC20("Nippon Idol Token", "NIDT") ERC20Capped(CAP_AMOUNT) {}

  function mint(address to, uint256 amount) external {
    ERC20Capped._mint(to, amount);
  }
}