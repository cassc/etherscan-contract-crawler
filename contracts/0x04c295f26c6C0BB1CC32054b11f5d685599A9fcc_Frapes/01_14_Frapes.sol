//SPDX-License-Identifier: MIT
//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./ERC721A.sol";

contract Frapes is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public baseURI;
  uint256 offset;

  struct SaleConfig {
    uint256 priceInETH;
    uint256 maxInternalMints;
    uint256 maxSupply;
    uint256 maxPerPartner;
    uint256 maxPerPresale;
    uint256 maxPerTx;
    bool presaleStarted;
    bool publicSaleStarted;
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public presaleList;
  mapping(address => uint256) public partnerList;

  constructor(
    string memory name,
    string memory symbol
  ) ERC721A(name, symbol) {
    // Initialize saleConfig with default values
    saleConfig.priceInETH = 0.01 ether;
    saleConfig.maxInternalMints = 50;
    saleConfig.maxSupply = 6666;
    saleConfig.maxPerPartner = 4;
    saleConfig.maxPerPresale = 3;
    saleConfig.maxPerTx = 10;
    saleConfig.presaleStarted = false;
    saleConfig.publicSaleStarted = false;
    baseURI = "https://frapes.mypinata.cloud/ipfs/QmcuJNKjcL2Rs3RooLYXYit7B4A2RA5oB9Rq367eoRw1uQ/";
  }

  modifier hasPresaleAccess() {
    require(
      presaleList[msg.sender] > 0 || partnerList[msg.sender] > 0,
      "You are not on the presale list!"
    );
    _;
  }

  modifier isValidETHPayment(uint256 numberOfTokens) {
    uint256 freeMints = 0;

    if (partnerList[msg.sender] > 0) {
      freeMints = 1;
    }

    require(
      msg.value >= (numberOfTokens - freeMints) * saleConfig.priceInETH,
      "Incorrect ETH value sent"
    );
    _;
  }

  modifier isValidSupply(uint256 numberOfTokens) {
    require(
      totalSupply() + numberOfTokens <= saleConfig.maxSupply,
      "Not enough remaining tokens"
    );
    _;
  }

  modifier presaleActive() {
    require(saleConfig.presaleStarted, "Presale is not active");
    _;
  }

  modifier publicSaleActive() {
    require(saleConfig.publicSaleStarted, "Public sale is not open");
    _;
  }

  modifier maxPresaleMints(uint256 numberOfTokens) {
    uint256 numberAllowed = saleConfig.maxPerPresale;

    if (partnerList[msg.sender] > 0) {
      numberAllowed = saleConfig.maxPerPartner;
    }

    require(
      numberMinted(msg.sender) + numberOfTokens <= numberAllowed,
      "Too many presale mints"
    );
    _;
  }

  modifier maxMintsPerTx(uint256 numberOfTokens) {
    require(numberOfTokens <= saleConfig.maxPerTx, "Minting too many tokens at once");
    _;
  }

  function presaleMint(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    presaleActive
    hasPresaleAccess
    isValidETHPayment(numberOfTokens)
    isValidSupply(numberOfTokens)
    maxPresaleMints(numberOfTokens)
  {
    uint256 freeMints = 0;

    if (partnerList[msg.sender] > 0) {
      freeMints++;
      partnerList[msg.sender] = 0;
    } else {
      presaleList[msg.sender] = 0;
    }

    _safeMint(msg.sender, numberOfTokens);

    refundIfOver(saleConfig.priceInETH * (numberOfTokens - freeMints));
  }

  function publicMint(uint256 numberOfTokens)
    external
    payable
    nonReentrant
    publicSaleActive
    isValidETHPayment(numberOfTokens)
    isValidSupply(numberOfTokens)
    maxMintsPerTx(numberOfTokens)
  {
    uint256 freeMints = 0;
    if (partnerList[msg.sender] > 0) {
      freeMints++;
      partnerList[msg.sender] = 0;
    }

    _safeMint(msg.sender, numberOfTokens);

    refundIfOver(saleConfig.priceInETH * (numberOfTokens - freeMints));
  }

  function refundIfOver(uint256 priceInETH) private {
    require(msg.value >= priceInETH, "Need to send more ETH");
    if (msg.value > priceInETH) {
      payable(msg.sender).transfer(msg.value - priceInETH);
    }
  }

  function seedPartnerList(address[] memory addresses)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      partnerList[addresses[i]] = 1;
    }
  }

  function seedPresaleList(address[] memory addresses)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      presaleList[addresses[i]] = 1;
    }
  }

  // Internal mints for marketing/promotional purposes
  function teamMint(uint256 numberOfTokens) external isValidSupply(numberOfTokens) onlyOwner {
    require(
      numberMinted(msg.sender) + numberOfTokens <= saleConfig.maxInternalMints,
      "Cannot mint more than allocation"
    );
    _safeMint(msg.sender, numberOfTokens);
  }

  function setPrice(uint256 _newPrice) external onlyOwner {
    saleConfig.priceInETH = _newPrice;
  }

  function setMaxInternalMints(uint256 _newMaxInternalMints) external onlyOwner {
    saleConfig.maxInternalMints = _newMaxInternalMints;
  }

  function setMaxSupply(uint256 _newMaxSupply) external onlyOwner {
    require(
      _newMaxSupply <= totalSupply(),
      "Cannot set max supply to greater than current supply"
    );

    saleConfig.maxSupply = _newMaxSupply;
  }

  function setMaxPerPresale(uint256 _newMaxPerPresale) external onlyOwner {
    saleConfig.maxPerPresale = _newMaxPerPresale;
  }

  function setPresale(bool isStarted) external onlyOwner {
    saleConfig.presaleStarted = isStarted;
  }

  function setPublicSale(bool isStarted) external onlyOwner {
    saleConfig.publicSaleStarted = isStarted;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}