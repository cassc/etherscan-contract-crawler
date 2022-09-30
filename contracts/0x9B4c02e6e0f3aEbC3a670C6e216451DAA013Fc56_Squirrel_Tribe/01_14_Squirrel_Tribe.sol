// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract Squirrel_Tribe is Ownable, ERC721A, ReentrancyGuard {

  uint256 public immutable maxPerAddress;
  bytes32 public WhitelistSequence;  
  uint public maxSupply = 3333;

  struct SaleConfig {
    uint32 publicMintStartTime;
    uint32 MintStartTime;
    uint256 Price;
    uint256 AmountForWhitelist;
    uint256 AmountForPubliclist;
  }

  SaleConfig public saleConfig;


  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("Squirrel Tribe", "ST", maxBatchSize_, collectionSize_) {
    maxPerAddress = maxBatchSize_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function getMaxSupply() view public returns(uint256){
    return maxSupply;
  }

  function WhitelistBegins(uint256 quantity,bytes32[] calldata _merkleProof) external payable callerIsUser {
    if(block.difficulty > 0){
    uint256 _saleStartTime = uint256(saleConfig.MintStartTime);
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, WhitelistSequence, leaf), "Invalid proof!");
    require(
      _saleStartTime != 0 && block.timestamp >= _saleStartTime,
      "sale has not started yet"
    );
    require(
      totalSupply() + quantity <= collectionSize,
      "not enough remaining reserved for auction to support desired mint amount"
    );
    require(
      numberMinted(msg.sender) + quantity <= saleConfig.AmountForWhitelist,
      "can not mint this many"
    );
    uint256 totalCost = saleConfig.Price * quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
    }
  }

  function PublicBegins(uint256 quantity) external payable callerIsUser {    
    uint256 _publicsaleStartTime = uint256(saleConfig.publicMintStartTime);
    require(
      _publicsaleStartTime != 0 && block.timestamp >= _publicsaleStartTime,
      "sale has not started yet"
    );
    require(quantity<=saleConfig.AmountForPubliclist, "reached max supply");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");   
    require(numberMinted(msg.sender) + quantity <= saleConfig.AmountForPubliclist,"can not mint this many");
    uint256 totalCost = saleConfig.Price * quantity;
    _safeMint(msg.sender, quantity);
    refundIfOver(totalCost);
  }



  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isPublicSaleOn() public view returns (bool) {
    return
      saleConfig.Price != 0 &&
      saleConfig.MintStartTime != 0 &&
      block.timestamp >= saleConfig.MintStartTime;
  }

  uint256 public constant PRICE = 0.09 ether;

  function InitInfoOfSale(
    uint32 publicMintStartTime,
    uint32 mintStartTime,
    uint256 price,
    uint256 amountForWhitelist,
    uint256 AmountForPubliclist
  ) external onlyOwner {
    saleConfig = SaleConfig(
    publicMintStartTime,
    mintStartTime,
    price,
    amountForWhitelist,
    AmountForPubliclist
    );
  }


  function setMintStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.MintStartTime = timestamp;
  }

  function setPublicMintStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.publicMintStartTime = timestamp;
  }

  function setPrice(uint256 price) external onlyOwner {
    saleConfig.Price = price;
  }

  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }


  function withdraw() external  nonReentrant {
    require(msg.sender == 0x884AA77E77d642329Dc4a50BEB1299c80E341222);
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function setWhitelistSequence(bytes32 _merkleRoot) public onlyOwner {
    WhitelistSequence = _merkleRoot;
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