// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract StarFighter is Ownable, ERC721A, ReentrancyGuard {

  uint256 public immutable maxPerAddressDuringMint;
  bytes32 public WhitelistMerkleRoot;
  bytes32 public PublicMerkleRoot;

  struct SaleConfig {
    uint32 MintStartTime;
    uint256 Price;
    uint256 AmountForWhitelist;
    uint256 AmountForPublic;
  }

  SaleConfig public saleConfig;
  uint256 public constant PRICE = 0.01 ether;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) ERC721A("Star Fighter", "SF", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function WhilteListMint(uint256 quantity,bytes32[] calldata _merkleProof) external payable callerIsUser {
    uint256 _saleStartTime = uint256(saleConfig.MintStartTime);
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, WhitelistMerkleRoot, leaf), "Invalid proof!");
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

  function PublicMint(bytes32[] calldata _merkleProof) external payable callerIsUser {
    uint256 price = uint256(saleConfig.Price);
    uint256 _saleStartTime = uint256(saleConfig.MintStartTime);
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, PublicMerkleRoot, leaf), "Invalid proof!");
    require(
      _saleStartTime != 0 && block.timestamp >= _saleStartTime,
      "sale has not started yet"
    );
    require(totalSupply() + 1 <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) == 0,
      "only can mint once"
    );
    _safeMint(msg.sender, 1);
    refundIfOver(price);
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

  

  function InitInfoOfSale(
    uint32 mintStartTime,
    uint256 price,
    uint256 amountForWhitelist,
    uint256 amountForPublic
  ) external onlyOwner {
    saleConfig = SaleConfig(
    mintStartTime,
    price,
    amountForWhitelist,
    amountForPublic
    );
  }

  function setMintStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.MintStartTime = timestamp;
  }

  function setPrice(uint256 price) external onlyOwner {
    saleConfig.Price = price;
  }

  // // metadata URI
  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function withdrawMoney() external  nonReentrant {
    require(msg.sender == 0x2B0B9Df04ac37bF164f64261db871493fad74A80);
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }

  function setWhitelistMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    WhitelistMerkleRoot = _merkleRoot;
  }

  function setPublicMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    PublicMerkleRoot = _merkleRoot;
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