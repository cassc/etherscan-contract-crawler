// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


/*
 * By interacting with this smart contract you agree to our terms and conditions: 
 * https://gcds.com/goto-content/nft-terms-and-conditions
 */

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./FiatMintable.sol";

contract GCDSWirdos is ERC721Enumerable, ERC721Pausable, FiatMintable {
  using Strings for uint256;

  // File extension for metadata file
  string private constant _EXTENSION = ".json";
  
  // ID for ERC-2981 Royalty fee standard
  bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
  
  // The base domain for the tokenURI
  string private _baseTokenURI;

  // Royalty percentage fee
  uint96 private _royaltyPercent;
  
  constructor(string memory baseTokenURI, uint96 royaltyPercent) ERC721("GCDS Wirdos", "WIRDO") FiatMintable() {
    _baseTokenURI = baseTokenURI;
    _royaltyPercent = royaltyPercent;
  }

  function _mintTokensTo(address to, uint amount) internal override {
    uint256 startIndex = totalSupply() + 1;
    uint256 lastIndex = startIndex + amount;

    for (uint256 i = startIndex; i < lastIndex; i++) {
      _safeMint(to, i);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string memory baseURI) public onlyOwner {
    _baseTokenURI = baseURI;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _EXTENSION));
  }

  function setRoyaltyPercentage(uint96 royaltyPercent) public onlyOwner {
    _royaltyPercent = royaltyPercent;
  }

  function getRoyaltyPercentage() public view returns (uint) {
    return _royaltyPercent;
  }

  function setPaused(bool pause) public onlyOwner {
    if (pause && !paused()) {
      _pause();
    }

    if (!pause && paused()) {
      _unpause();
    }
  }

  // ERC-2981 interface method
  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount) {
    tokenId = tokenId; // to stop warnings
    return (owner(), (salePrice * _royaltyPercent) / 10000);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override(ERC721Pausable, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
    if (interfaceId == _INTERFACE_ID_ERC2981) {
      return true;
    }

    return super.supportsInterface(interfaceId);
  }
}