// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract GlizzyGang is ERC721, Ownable, ReentrancyGuard {
  using Address for address;

  uint256 constant public PRE_MINTED = 251; // migrated from OpenSea
  uint256 constant public MAX_MINT = 10;
  uint256 constant public MINT_PRICE = 0.0555 ether;
  uint256 constant public MAX_SUPPLY = 5555;

  string public PROVENANCE_HASH; // sha256
  bool public revealed;
  bool public saleActive;
  string public metadataURI;

  uint256 internal _tokenIds = PRE_MINTED;
  uint256 internal _reserved;
  uint256 internal _tokenOffset;
  string internal _baseTokenURI;
  string internal _placeholderURI;

  constructor(
  )
    ERC721("GlizzyGang", "GLIZZY")
  {
    _placeholderURI = "";
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIds;
  }

  function tokenOffset() public view returns (uint256) {
    require(_tokenOffset != 0, "Offset has not been generated");

    return _tokenOffset;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

    return revealed ? ERC721.tokenURI(tokenId) : _placeholderURI;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseTokenURI(string memory URI) public onlyOwner {
    _baseTokenURI = URI;
  }

  function setMetadataURI(string memory URI) public onlyOwner {
    metadataURI = URI;
  }

  function setPlaceholderURI(string memory URI) public onlyOwner {
    _placeholderURI = URI;
  }

  function mint(uint256 amount) public payable nonReentrant {
    _mintAmount(amount, msg.sender);
  }

  function _mintAmount(uint256 amount, address to) internal {
    require(_tokenIds + amount <= MAX_SUPPLY, "Exceeds maximum number of tokens");

    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _tokenIds);
      _tokenIds += 1;
    }
  }

  function withdraw() nonReentrant onlyOwner public {
    Address.sendValue(payable(msg.sender), address(this).balance);
  }
}