// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract Token is ERC20, ERC20Burnable {
  constructor() ERC20("Crypto Lottery", "CL") {}
}