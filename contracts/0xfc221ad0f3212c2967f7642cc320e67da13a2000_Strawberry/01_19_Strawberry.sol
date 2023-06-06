// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/Counters.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

import '../interfaces/IStrawberry.sol';
import "../interfaces/IStrawberryMetadata.sol";
import "./BigFarmer.sol";

contract Strawberry is ERC721Enumerable, BigFarmer, Ownable, IStrawberry, IStrawberryMetadata {
  using Counters for Counters.Counter;
  using Strings for uint256;

  uint256 public constant BERRIES_SPECIAL = 5;
  uint256 public constant BERRIES_GIFT = 95;
  uint256 public constant BERRIES_PUBLIC = 9_900;
  uint256 public constant BERRIES_MAX = BERRIES_SPECIAL + BERRIES_GIFT + BERRIES_PUBLIC;
  uint256 public constant PURCHASE_LIMIT = 20;
  uint256 public constant PRICE = 25_000_000_000_000_000; // 0.025 ETH

  bool public areTokensRevealed = false;
  string public seed = '';
  string public proof = '';

  string private _contractURI = '';
  string private _tokenBaseURI = '';
  bool private _isActive = false;

  Counters.Counter private _specialStrawberries;
  Counters.Counter private _giftStrawberries;
  Counters.Counter private _publicStrawberries;

  constructor(string memory name, string memory symbol) ERC721(name, symbol) {
    _mintSpecials();
  }

  // Set the seed phrase for the generation of Strawberries
  function setSeed(string memory seedString) external override onlyOwner {
    seed = seedString;
  }

  // Set the proof hash
  function setProof(string memory proofString) external override onlyOwner {
    proof = proofString;
  }

  // Set the if purchase and minting is active
  function setActive(bool isActive) external override onlyOwner {
    _isActive = isActive;
  }

  // Set the contractURI
  function setContractURI(string memory URI) external override onlyOwner {
    _contractURI = URI;
  }

  // Set the baseURI
  function setBaseURI(string memory URI) external override onlyOwner {
    _tokenBaseURI = URI;
  }

  // Set if the tokens are revealed
  function setTokensRevealed(bool tokensRevealed) external override onlyOwner {
    areTokensRevealed = tokensRevealed;
  }

  // Purchase a single token
  function purchase(uint256 numberOfTokens) external override payable {
    require(_isActive, 'Contract is not active');
    require(numberOfTokens <= PURCHASE_LIMIT, 'Can only mint up to 20 tokens');
    require(_publicStrawberries.current() < BERRIES_PUBLIC, 'Purchase would exceed BERRIES_PUBLIC');
    require(PRICE * numberOfTokens <= msg.value, 'ETH amount is not sufficient');

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 tokenId = BERRIES_SPECIAL + BERRIES_GIFT + _publicStrawberries.current();

      if (_publicStrawberries.current() < BERRIES_PUBLIC) {
        _publicStrawberries.increment();
        _safeMint(msg.sender, tokenId);
      }
    }
  }

  // Gift a single token
  function gift(address to) external override payable onlyOwner {
    require(totalSupply() < BERRIES_MAX, 'All tokens have been minted');
    require(_specialStrawberries.current() < BERRIES_GIFT, 'No tokens left to gift');

    uint256 tokenId = BERRIES_SPECIAL + _specialStrawberries.current();

    _specialStrawberries.increment();
    _safeMint(to, tokenId);
  }

  // Returns URL for storefront-level metadata
  function contractURI() public view override returns (string memory) {
    return _contractURI;
  }

  // Returns URL for token-level metadata
  function tokenURI(uint256 tokenId) public view override(ERC721, IStrawberryMetadata) returns (string memory) {
    require(_exists(tokenId), 'Token does not exist');

    if (areTokensRevealed) {
      return string(abi.encodePacked(_tokenBaseURI, tokenId.toString()));
    }

    return _tokenBaseURI;
  }

  // Withdraw contract balance
  function withdraw() external override onlyOwner {
    uint256 balance = address(this).balance;

    payable(msg.sender).transfer(balance);
  }

  // Mint the Special Strawberries to contract owner
  function _mintSpecials() internal {
    require(totalSupply() < BERRIES_SPECIAL, 'All special tokens have been minted');

    for (uint256 i = 0; i < BERRIES_SPECIAL; i++) {
      _safeMint(msg.sender, totalSupply());
    }
  }

  // Override _beforeTokenTransfer hook to check for Big Farmer status
  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    super._beforeTokenTransfer(from, to, tokenId);

    _checkBigFarmerStatus(from, to);
  }
}