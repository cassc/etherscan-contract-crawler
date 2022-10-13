// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract KingToken is ERC20 {
  constructor() ERC20("King Token", "KING") {
    _mint(address(this), 1_000_000_000 * (10 ** uint256(decimals())));
    _approve(address(this), msg.sender, totalSupply());
  }
}