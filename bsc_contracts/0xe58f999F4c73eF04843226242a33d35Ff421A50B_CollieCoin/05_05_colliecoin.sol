// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CollieCoin is ERC20 {
  constructor() ERC20("COL", "CollieCoin") {
    _mint(msg.sender, 3500 * 10 ** 18);
  }
}