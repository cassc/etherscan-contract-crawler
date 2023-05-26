// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract CrashTestJoyride is Ownable, ERC721A, ReentrancyGuard {
  uint256 public immutable maxTokensPerTx;
  uint256 public immutable maxTokensInPresale;
  uint256 public immutable amountForDevs;

  struct SaleConfig {
    uint32 preSaleStartTime;
    uint32 publicSaleStartTime;
    uint64 price;
  }
  
  SaleConfig public saleConfig;

  bytes32 public merkleRoot;

  mapping(address => uint256) private _tokensClaimedInPresale;

  constructor(
    uint256 maxBatchSize_,
    uint256 collectionSize_,
    uint256 maxTokensInPreSale_,
    uint256 amountForDevs_
  ) ERC721A("CrashTestJoyride", "CTJR", maxBatchSize_, collectionSize_) {
    maxTokensPerTx = maxBatchSize_;
    maxTokensInPresale = maxTokensInPreSale_;
    amountForDevs = amountForDevs_;
  }

  function preSaleMint(uint256 quantity, bytes32[] memory proof) external payable {
    uint256 price = uint256(saleConfig.price);
    require(price != 0, "presale has not begun yet");
    uint256 preSaleStartTime = uint256(saleConfig.preSaleStartTime);
    require(
      preSaleStartTime != 0 && block.timestamp >= preSaleStartTime,
      "presale has not started yet"
    );
    if (MerkleProof.verify(proof, merkleRoot, keccak256(abi.encodePacked(msg.sender)))) {
        require(_tokensClaimedInPresale[msg.sender] + quantity <= maxTokensInPresale,
                "You cannot mint any more CTJR NFTs during the presale");
        require(price * quantity <= msg.value, "Ether value sent is not correct");
        _safeMint(msg.sender, quantity);
    } else {
        revert("Not on the presale list");
    }
    _tokensClaimedInPresale[msg.sender] += quantity;
  }

  function publicSaleMint(uint256 quantity) external payable {
    SaleConfig memory config = saleConfig;
    uint256 price = uint256(config.price);
    require(price != 0, "public sale has not begun yet");
    uint256 publicSaleStartTime = uint256(config.publicSaleStartTime);
    require(
      publicSaleStartTime != 0 && block.timestamp >= publicSaleStartTime,
      "public sale has not started yet"
    );
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(price * quantity <= msg.value, "Ether value sent is not correct");
    _safeMint(msg.sender, quantity);
  }

  // For devs, marketing etc.
  function devMint(address _to, uint256 quantity) external onlyOwner {
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
      _safeMint(_to, maxBatchSize);
    }
  }

  function setPublicSaleStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.publicSaleStartTime = timestamp;
  }

  function setPreSaleStartTime(uint32 timestamp) external onlyOwner {
    saleConfig.preSaleStartTime = timestamp;
  }

  function setPrice(uint64 price) external onlyOwner {
    saleConfig.price = price;
  }

  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

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