//SPDX-License-Identifier: Unlicense
pragma solidity ^0.7.0;

import "./../ERC721Mintable.sol";

contract SampleERC721 is ERC721Mintable {
  constructor(string memory _name, string memory _symbol)
    ERC721Mintable(_name, _symbol) {
  }
}