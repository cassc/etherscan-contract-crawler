//SPDX-FileCopyrightText: 2022 GDA
//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract GDA is ERC721, Ownable {
  string public baseURI;
  uint256 public constant totalSupply = 150;
  bool public lock = false;

  constructor(string memory _newBaseURI) ERC721("GDA", "GDA") {
    baseURI = _newBaseURI;
  }

  function airdrop(address[] memory list) public onlyOwner {
    require(!lock, "lock");
    lock = true;
    uint256 len = list.length;
    for (uint256 i = 0; i < len; ++i) {
      _mint(list[i], i);
    }
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }
}