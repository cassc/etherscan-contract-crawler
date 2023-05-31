// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {ERC20} from "./ERC20.sol";

contract HMX is ERC20 {
  constructor(uint256 _initialSupply) ERC20("HMX", "HMX") {
    _mint(_msgSender(), _initialSupply);
  }
}
