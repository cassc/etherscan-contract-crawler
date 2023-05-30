// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Consecutive.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TUW is ERC721, Ownable {
  using Counters for Counters.Counter;

  // Constants
  uint256 public constant TOTAL_SUPPLY = 500;

  Counters.Counter private currentTokenId;

  /// @dev Base token URI used as a prefix by tokenURI().
  string public baseTokenURI;

  constructor() ERC721("The Underwatch", "TUW") {
    baseTokenURI = "";
  }

  function mintTo(address recipient) public payable onlyOwner returns (uint256) {
    uint256 tokenId = currentTokenId.current();
    require(tokenId < TOTAL_SUPPLY, "Max supply reached");
    currentTokenId.increment();
    uint256 newItemId = currentTokenId.current();
    _safeMint(recipient, newItemId);
    return newItemId;
  }

  function mintBatch(address recipient, uint batchSize) public payable onlyOwner returns (bool) {
    for (uint i = 1; i <= batchSize; i++) {
      uint256 tokenId = currentTokenId.current();
      require(tokenId < TOTAL_SUPPLY, "Max supply reached");
      currentTokenId.increment();
      uint256 newItemId = currentTokenId.current();
      _safeMint(recipient, newItemId);
    }
    return true;
  }

  /// @dev Returns an URI for a given token ID
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  /// @dev Sets the base token URI prefix.
  function setBaseTokenURI(string memory _baseTokenURI) public onlyOwner {
    baseTokenURI = _baseTokenURI;
  }
}