// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol';

contract Pace is ERC20Burnable {
  uint256 internal constant TOTAL_SUPPLY = 100000000 ether;

  constructor() ERC20('3SPACE ART', 'PACE') {
    _mint(msg.sender, TOTAL_SUPPLY);
  }
}