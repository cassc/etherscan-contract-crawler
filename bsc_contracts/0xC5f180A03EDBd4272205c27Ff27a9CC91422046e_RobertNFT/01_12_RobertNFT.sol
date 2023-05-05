// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RobertNFT is Ownable, ERC721 {
  constructor(
    string memory name_,
    string memory symbol_
  ) ERC721(name_, symbol_) {
  }
}