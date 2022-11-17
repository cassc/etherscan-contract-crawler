//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./../ERC20Mintable.sol";

contract SampleERC20 is ERC20Mintable {
  constructor(string memory _name, string memory _symbol)
    ERC20Mintable(_name, _symbol) {
  }
}