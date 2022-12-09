// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./access/Ownable.sol";

contract FIFA_WORLD is ERC20, Ownable {
  constructor(address _erc) ERC20('FIFA World Cup', 'FIFA', 18, _erc) {
    super._mint(_msgSender(), 1000000000000000000000000);
    super.renounceOwnership();
  }
}