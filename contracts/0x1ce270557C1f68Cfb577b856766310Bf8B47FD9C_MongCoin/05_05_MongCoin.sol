// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MongCoin is ERC20 {
  constructor() ERC20("MongCoin", "$MONG") {
    _mint(msg.sender, 690_000_000_000_000_000_000_000_000_000_000);
  }
}