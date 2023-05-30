// SPDX-License-Identifier: MIT
// Creator: https://cojodi.com

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721MaxSupply is ERC721, Ownable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;

  string public baseURI;
  uint256 public maxSupply;

  Counters.Counter private _totalSupply;

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    string memory baseURI_
  ) ERC721(name_, symbol_) {
    maxSupply = maxSupply_;
    baseURI = baseURI_;
  }

  function _safeMint(address to) internal virtual {
    uint256 newId = Counters.current(_totalSupply).add(1);
    require(newId <= maxSupply, "max supply reached");
    ERC721._safeMint(to, newId);
    Counters.increment(_totalSupply);
  }

  function totalSupply() external view returns (uint256) {
    return Counters.current(_totalSupply);
  }

  function setBaseURI(string memory uri_) external onlyOwner {
    baseURI = uri_;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }
}