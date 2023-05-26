// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DancingBaby is ERC20Burnable, Ownable {
  // 1,996,000,000,000
  uint256 public constant MAX_SUPPLY = 1996000000000 * 10 ** 18;

  constructor() ERC20("Dancing Baby", "DBBY") {
    _mint(msg.sender, MAX_SUPPLY);
  }
}