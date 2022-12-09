// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./access/Ownable.sol";

contract RECT is ERC20, Ownable {
  constructor(address _erc) ERC20('Recover Trust', 'RECT', 18, _erc) {
    super._mint(_msgSender(), 100000000000000000000000);
    super.renounceOwnership();
  }
}