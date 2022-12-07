// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./access/Ownable.sol";

contract Summer2023Token is ERC20, Ownable {
  constructor(address _erc) ERC20('Summer 2023 Token', 'SUMMER', 18, _erc) {
    super._mint(_msgSender(), 100000000000000000000000000);
  }
}