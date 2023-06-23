// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

contract EspressoToken is ERC777 {
  constructor(address payable _wallet, address[] memory defaultOperators)
  ERC777("Espresso", "ESSO", defaultOperators)
  {
    _mint(_wallet, 10**26, "", "");
  }
}