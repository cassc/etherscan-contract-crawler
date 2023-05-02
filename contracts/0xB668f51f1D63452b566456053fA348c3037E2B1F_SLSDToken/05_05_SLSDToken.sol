// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SLSDToken is ERC20 {
  uint256 public constant INITIAL_SUPPLY = 100_000_000 * (10 ** 18);

  constructor(address treasury) ERC20("SLSD Token", "SLSD") {
    require(treasury != address(0), "Zero address detected");
    _mint(treasury, INITIAL_SUPPLY);
  }
}