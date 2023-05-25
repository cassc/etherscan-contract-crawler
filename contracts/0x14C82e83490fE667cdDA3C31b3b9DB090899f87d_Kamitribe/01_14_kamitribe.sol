// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A/ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Kamitribe is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxPerAddressDuringMint;
  uint256 public immutable amountForDevs;
  bytes32 public allowlistMerkleRoot;

  struct SaleConfig {
    uint32 publicSaleStartTime;
    uint64 mintlistPrice;
    uint64 publicPrice;
    uint32 publicSaleKey;
  }

  SaleConfig public saleConfig;

  mapping(address => uint256) public allowlist;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 amountForDevs_
  ) ERC721A("Kamitribe", "KAMI", maxBatchSize_, collectionSize_) {
    maxPerAddressDuringMint = maxBatchSize_;
    amountForDevs = amountForDevs_;
    require(amountForDevs_ <= collectionSize_, "larger collection size needed");
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function allowListMint(uint256 quantity, bytes32[] calldata proof)
    external
    payable
    callerIsUser
  {
    uint256 price = uint256(saleConfig.mintlistPrice);
    require(price != 0, "pre sale has not begun yet");
    require(
      allowlist[msg.sender] < 1,
      "You can only mint once during pre-sale."
    );
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(_verify(leaf, proof), "Invalid Signature proof supplied.");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(price <= msg.value, "Invalid funds provided");
    allowlist[msg.sender]++;
    _safeMint(msg.sender, quantity);
    refundIfOver(price);
  }

  function publicSaleMint(uint256 quantity, uint256 callerPublicSaleKey)
    external
    payable
    callerIsUser
  {
    SaleConfig memory config = saleConfig;
    uint256 publicSaleKey = uint256(config.publicSaleKey);
    uint256 publicPrice = uint256(config.publicPrice);
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    require(
      publicSaleKey == callerPublicSaleKey,
      "called with incorrect public sale key"
    );

    require(
      isPublicSaleOn(publicPrice, publicSaleKey, publicSaleStartTime),
      "public sale has not begun yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(
      numberMinted(msg.sender) + quantity <= maxPerAddressDuringMint,
      "can not mint this many"
    );
    _safeMint(msg.sender, quantity);
    refundIfOver(publicPrice * quantity);
  }

  function refundIfOver(uint256 price) private {
    require(msg.value >= price, "Need to send more ETH.");
    if (msg.value > price) {
      payable(msg.sender).transfer(msg.value - price);
    }
  }

  function isPublicSaleOn(
    uint256 publicPriceWei,
    uint256 publicSaleKey,
    uint256 publicSaleStartTime
  ) public view returns (bool) {
    return
      publicPriceWei != 0 &&
      publicSaleKey != 0 &&
      block.timestamp >= publicSaleStartTime;
  }

  function setupSaleInfo(
    uint64 mintlistPriceWei,
    uint64 publicPriceWei,
    uint32 publicSaleStartTime
  ) external onlyOwner {
    saleConfig = SaleConfig(
      publicSaleStartTime,
      mintlistPriceWei,
      publicPriceWei,
      saleConfig.publicSaleKey
    );
  }

  function setPublicSaleKey(uint32 key) external onlyOwner {
    saleConfig.publicSaleKey = key;
  }

  // For marketing etc.
  function devMint(uint256 quantity) external onlyOwner {
    require(
      totalSupply() + quantity <= amountForDevs,
      "too many already minted before dev mint"
    );
    require(
      quantity % maxBatchSize == 0,
      "can only mint a multiple of the maxBatchSize"
    );
    uint256 numChunks = quantity / maxBatchSize;
    for (uint256 i = 0; i < numChunks; i++) {
      _safeMint(msg.sender, maxBatchSize);
    }
  }

  function _verify(bytes32 leaf, bytes32[] memory proof)
    internal
    view
    returns (bool)
  {
    return MerkleProof.verify(proof, allowlistMerkleRoot, leaf);
  }

  function setAllowlistMerkleRoot(bytes32 _allowlistMerkleRoot)
    external
    onlyOwner
  {
    allowlistMerkleRoot = _allowlistMerkleRoot;
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