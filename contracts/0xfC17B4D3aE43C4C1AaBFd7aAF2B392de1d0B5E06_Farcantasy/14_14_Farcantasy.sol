// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

contract Farcantasy is ERC721, Ownable, Versioned {
  using Counters for Counters.Counter;

  Counters.Counter public tokenId;
  uint256 public idCap = 1000;

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    string memory version
  ) ERC721(tokenName, tokenSymbol) Versioned(version) {
    // Start with token 1
    tokenId.increment();
  }

  function mint() external payable {
    // Check if value is > 10 matic
    require(msg.value >= 10 ether, "Value must be greater than 10");
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