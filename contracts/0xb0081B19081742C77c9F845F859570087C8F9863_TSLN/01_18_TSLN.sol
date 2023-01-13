// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "operator-filter-registry/src/DefaultOperatorFilterer.sol";

contract TSLN is ERC721, ERC2981, Ownable, Pausable, DefaultOperatorFilterer {
  string constant public TOKEN_NAME = "The Secret Life of Nouns";
  string constant public TOKEN_SYMBOL = "TSLN";

  uint256 public tokenId = 0;

  uint256 public price;
  uint256 public supplies;
  uint256 public mintLimit;
  string public baseURI;
  string public contractURI;

  constructor(uint256 _price, uint96 _royaltyFraction, uint256 _supplies, uint256 _mintLimit, string memory _baseUri, string memory _contractURI) ERC721(TOKEN_NAME, TOKEN_SYMBOL) {
    price = _price;
    supplies = _supplies;
    mintLimit = _mintLimit;
    baseURI = _baseUri;
    contractURI = _contractURI;

    _setDefaultRoyalty(address(this), _royaltyFraction);
    _pause();
  }

  function mint(uint256 _tokens) external payable {
    require(_tokens + balanceOf(msg.sender) <= mintLimit, "You reach the max mint limit");
    require(_tokens + tokenId <= supplies, "Sold Out");
    require(msg.value >= price * _tokens, "Insufficient Funds");

    for (uint i = 0; i < _tokens; i++) {
      _safeMint(msg.sender, tokenId++);
    }
  }

  ////////////////////////////////////////////
  // LIB OVERRIDE STUFF ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC2981) returns (bool) {
    return ERC721.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
  }

  // DefaultOperatorFilterer
  function setApprovalForAll(address operator, bool approved) public override onlyAllowedOperatorApproval(operator) {
    super.setApprovalForAll(operator, approved);
  }

  function approve(address operator, uint256 _tokenId) public override onlyAllowedOperatorApproval(operator) {
    super.approve(operator, _tokenId);
  }

  function transferFrom(address from, address to, uint256 _tokenId) public override onlyAllowedOperator(from) {
    super.transferFrom(from, to, _tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 _tokenId) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, _tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 _tokenId, bytes memory data) public override onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, _tokenId, data);
  }
  // LIB OVERRIDE STUFF ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
  ////////////////////////////////////////////

  ////////////////////////////////////////////
  // INTERNAL STUFF   ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function _beforeTokenTransfer(address _from, address _to, uint256 _tokenId, uint256 _batchSize) internal whenNotPaused override {
    super._beforeTokenTransfer(_from, _to, _tokenId, _batchSize);
  }
  // INTERNAL STUFF   ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
  ////////////////////////////////////////////
  // OWNER ONLY STUFF ↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓↓
  function setBaseURI(string memory _baseUri) external onlyOwner {
    baseURI = _baseUri;
  }

  function setContractURI(string memory _contractURI) external onlyOwner {
    contractURI = _contractURI;
  }

  function setSupplies(uint256 _supplies) external onlyOwner {
    supplies = _supplies;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMintLimit(uint256 _mintLimit) external onlyOwner {
    mintLimit = _mintLimit;
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }

  function changePrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setDefaultRoyalty(address _receiver, uint96 _royaltyFraction) external onlyOwner {
    _setDefaultRoyalty(_receiver, _royaltyFraction);
  }

  function airdrop(address[] memory addresses) external {
    require(addresses.length + tokenId <= supplies, "Sold Out");
    for (uint i = 0; i < addresses.length; i++) {
      _safeMint(addresses[i], tokenId++);
    }
  }

  function withdrawAll() external onlyOwner {
    (bool transferRes, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(transferRes, "Failed to withdraw the money");
  }
  // OWNER ONLY STUFF ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑
  ////////////////////////////////////////////
}