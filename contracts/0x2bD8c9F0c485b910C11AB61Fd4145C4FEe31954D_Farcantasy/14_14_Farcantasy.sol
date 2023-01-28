// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

contract Farcantasy is ERC721, Ownable, Versioned {
  using Counters for Counters.Counter;

  string public baseURI;
  Counters.Counter public tokenId;
  uint256 public idCap = 1000;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    string memory version,
    string memory _newBaseURI
  ) ERC721(tokenName, tokenSymbol) Versioned(version) {
    baseURI = _newBaseURI;
    // Start with token 1
    tokenId.increment();
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string memory _newBaseURI) external onlyOwner {
    baseURI = _newBaseURI;
  }

  function mint() external payable {
    // Check if value is > 0.0065 ETH
    require(msg.value >= 0.0065 ether, "Value must be greater than 0.0065");
    uint256 _tokenId = tokenId.current();
    require(_tokenId <= idCap, "Cap reached, check back later!");
    _safeMint(msg.sender, _tokenId);
    tokenId.increment();
    // Send value to owner
    payable(owner()).transfer(msg.value);
  }

  function setIdCap(uint256 _idCap) external onlyOwner {
    idCap = _idCap;
  }
}