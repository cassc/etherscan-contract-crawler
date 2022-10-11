// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFT is ERC721, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter private currentTokenId;

  mapping(uint256 => string) public provenances;
  mapping(uint256 => string) public tokenURIs;
  mapping(uint256 => bool) public frozen;

  constructor() ERC721("CryptoRxiv", "PAPER") {
  }

  function mintTo(address recipient, string memory _provenance, string memory _tokenURIs) public onlyOwner returns (uint256) {
    uint256 newItemId = currentTokenId.current();
    require(newItemId < 10000, "max number reached");
    currentTokenId.increment();
    provenances[newItemId] = _provenance;
    tokenURIs[newItemId] = _tokenURIs;
    frozen[newItemId] = false;
    _safeMint(recipient, newItemId);
    return newItemId;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "invalid token ID");
    string memory _tokenURI = tokenURIs[tokenId];
    return _tokenURI;
  }

  function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
    require(_exists(tokenId), "invalid token ID");
    require(!frozen[tokenId], "URI is frozen");
    tokenURIs[tokenId] = _tokenURI;
  }

  function freezeURI(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "invalid token ID");
    require(!frozen[tokenId], "URI is frozen");
    frozen[tokenId] = true;
  }
}