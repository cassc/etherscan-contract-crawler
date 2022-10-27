// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract RhinoWorld is Ownable, ERC721A, ReentrancyGuard {
  bool public saleActive = true;
  bool public saleDone = false;

  struct SaleConfig {
    uint32 whitelistSaleStartTime;
    uint256 WL_PRICE;
    uint32 publicSaleStartTime;
    uint256 PUBLIC_PRICE;
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public wllist;

  constructor(
    uint32 maxBatchSize_,
    uint256 collectionSize_,
    uint32 _whitelistSaleStartTime,
    uint32 _publicSaleStartTime
  ) ERC721A("Rhino World", "RHINOWORLD", maxBatchSize_, collectionSize_) {
    saleConfig.WL_PRICE = 0.15 ether;
    saleConfig.PUBLIC_PRICE = 0.25 ether;
    saleConfig.whitelistSaleStartTime = _whitelistSaleStartTime;
    saleConfig.publicSaleStartTime = _publicSaleStartTime;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.PUBLIC_PRICE);

    require(
      isPublicSaleOn(),
      "public sale has not begun yet"
    );

    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

 function wlSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 wlPrice = uint256(config.WL_PRICE);

    require(
      isWLSaleOn(),
      "wl sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    
    require(wllist[msg.sender] > 0, "no allocation available for this address");
    require(wllist[msg.sender] >= quantity, "trying to mint too much");
    
    wllist[msg.sender] = wllist[msg.sender] - quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(wlPrice * quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isPublicSaleOn() public view returns (bool) {
    return
      saleDone == false &&
      saleActive == true && 
      block.timestamp >= saleConfig.publicSaleStartTime;
  }

  function isWLSaleOn() public view returns (bool) {
    return
      saleDone == false &&
      saleActive == true && 
      block.timestamp >= saleConfig.whitelistSaleStartTime;
  }

  function addwllist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      wllist[addresses[i]] = numSlots[i];
    }
  }

  function devMint(uint256 quantity, address mintTo, string calldata reasoning) external onlyOwner {
    // Reasoning allows on chain visualization for dev mint call for future auditing i.e. devMint(100, address(BrandA), "Off chain sale with Brand A")
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    require(saleDone == false, "sale already over");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");

    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(mintTo, maxBatchSize);
    }
  }

  function toggleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  function EndSale() external onlyOwner {
    saleDone = true;
  }

  function updateSale(
    uint32 _whitelistSaleStartTime,
    uint256 _WL_PRICE,
    uint32 _publicSaleStartTime,
    uint256 _PUBLIC_PRICE
  ) external onlyOwner {
    saleConfig = SaleConfig(
      _whitelistSaleStartTime,
      _WL_PRICE,
      _publicSaleStartTime,
      _PUBLIC_PRICE
    );
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
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