// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PugCoin is ERC20 {
  constructor() ERC20("PUG", "PugCoin") {
    _mint(msg.sender, 2500 * 10 ** 18);
  }
}