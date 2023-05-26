// SPDX-License-Identifier: MIT

pragma solidity ^0.8.5;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "erc721a/contracts/ERC721A.sol" ; 
import "@openzeppelin/contracts/utils/Strings.sol";

contract DuckDrop is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  uint256 public immutable collectionSize ; 

  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
    uint64 publicPrice;
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_
  ) ERC721A("DuckDrop", "DD") {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
    collectionSize = collectionSize_; 

    require(
      amountForDevs_ <= collectionSize_,
      "larger collection size needed"
    );
  }

  
  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function allowlistMint(uint256 quantity) external payable callerIsUser {
    uint256 price = uint256(saleConfig.mintlistPrice)*quantity;
    require(price != 0, "allowlist sale has not begun yet");
    require(allowlist[msg.sender] > 0, "not eligible for allowlist mint");
    require(allowlist[msg.sender] >= quantity, "can't mint this many") ; 
    require(totalSupply() + 1 <= collectionSize-amountForDevs, "reached max supply");
    refundIfOver(price);
    allowlist[msg.sender] = allowlist[msg.sender]-quantity;
    _safeMint(msg.sender, quantity);
  }

  function publicSaleMint(uint256 quantity)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);

    require(
      isPublicSaleOn(publicPrice, publicSaleStartTime),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize-amountForDevs, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more crypto.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

// here
  function isPublicSaleOn(
    uint256 publicPriceWei,
    uint256 publicSaleStartTime
  ) public view returns (bool) {
    return
      publicPriceWei != 0 &&
      block.timestamp >= publicSaleStartTime;
  }

  function SetupSaleInfo(
    uint64 mintlistPriceWei,
    uint64 publicPriceWei,
    uint32 publicSaleStartTime
  ) external onlyOwner {
    saleConfig = SaleConfig(
      publicSaleStartTime,
      mintlistPriceWei,
      publicPriceWei
    );
  }

  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots)
    external
    onlyOwner
  {
    require(
      addresses.length == numSlots.length,
      "addresses does not match numSlots length"
    );
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
      require(totalSupply() + quantity <= collectionSize, "reached max supply"); 
      _safeMint(msg.sender, quantity);
  }

  function devMintTo(address[] memory addresses, uint256[] memory num) 
    external
    onlyOwner
  {
    require(
      addresses.length == num.length,
      "addresses does not match numSlots length"
    );
    require(totalSupply() +  addresses.length <= collectionSize, "reached max supply"); 
    for (uint256 i = 0; i < addresses.length; i++) {
        _safeMint(addresses[i], num[i]);
    }
  }
  // // metadata URI
  string private _baseTokenURI = 'https://jazbh74kwc.execute-api.ap-southeast-1.amazonaws.com/dev/dd_egg_metadata?token_id=' ;

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