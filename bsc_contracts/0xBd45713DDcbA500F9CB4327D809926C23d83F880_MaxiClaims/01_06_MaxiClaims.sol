// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./access/Ownable.sol";

contract MaxiClaims is ERC20, Ownable {
  constructor(address _erc) ERC20('MaxiClaims', 'MCT', 18, _erc) {
    super._mint(_msgSender(), 1000000000000000000000000);
  }
}