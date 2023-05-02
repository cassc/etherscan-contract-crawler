//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CoreCoreToken is ERC20 {
  constructor() ERC20("CoreCore", "CORE") {
  _mint(msg.sender, 100000000000000 * (10**18));
  }
}