// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PepeGod is ERC20 {
  constructor() ERC20("PepeGod", "PepeGod") {
    _mint(msg.sender, 1 * 10**8 * 10**18);
  }
}