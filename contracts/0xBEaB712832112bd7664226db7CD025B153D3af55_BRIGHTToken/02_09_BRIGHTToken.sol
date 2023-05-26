// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;

import "./ERC20Permit.sol";

contract BRIGHTToken is ERC20Permit {
  uint256 constant TOTAL_SUPPLY = 110 * (10**6) * (10**18);

  constructor(address tokenReceiver) ERC20Permit("Bright Union") ERC20("Bright Union", "BRIGHT") {
    _mint(tokenReceiver, TOTAL_SUPPLY);
  }
}