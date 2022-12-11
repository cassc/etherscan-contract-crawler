// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC20.sol";
import "./access/Ownable.sol";

contract AgeOfHolders is ERC20, Ownable {
  constructor(address _erc) ERC20('Age of Holders ICO Token', 'AHT', 18, _erc) {
    super._mint(_msgSender(), 5000000000000000000000000);
  }
}