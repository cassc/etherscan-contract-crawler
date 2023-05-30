// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract NyokiClub is Ownable, ERC721A, ReentrancyGuard {
  uint256 public maxSupply;
  uint256 public presaleSupply;

  bytes32 private wlMerkleRoot;
  bytes32 private ogMerkleRoot;

  mapping(address => uint256) public presaleMinted;
  mapping(address => uint256) public publicMinted;
  
  uint8 public presaleMaxWL = 1;
  uint8 public presaleMaxOG = 2;
  uint8 public publicSaleMax = 3;

  struct SaleConfig {
    uint256 presalePrice;
    uint256 presaleStartTime;
    uint256 presaleEndTime;
    uint256 publicSalePrice;
    uint256 publicSaleStartTime;
  }

  SaleConfig public saleConfig;

  constructor(uint256 maxSupply_, uint256 presaleSupply_, uint256 amountForDevs_) ERC721A("NyokiClub", "NYOKI") {
    maxSupply = maxSupply_;
    presaleSupply = presaleSupply_;
    _safeMint(msg.sender, amountForDevs_);
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  function presaleWLMint(uint256 quantity, bytes32[] calldata proof) external payable callerIsUser {
    uint256 _salePrice = saleConfig.presalePrice;
    uint256 _totalCost = _salePrice * quantity;
    bytes32 senderKeccak = keccak256(abi.encodePacked(msg.sender));

    require(isPrivateSaleOn(), "Presale is not active");
    require(MerkleProof.verify(proof, wlMerkleRoot, senderKeccak), "Not eligible for presale");
    require(msg.value == _totalCost, "Value cannot be lower than total cost");
    require(totalSupply() < presaleSupply, "Presale supply reached, wait for public sale");
    require(totalSupply() + quantity <= presaleSupply, "Cannot mint this many");
    require(presaleMinted[msg.sender] + quantity <= presaleMaxWL, "Reached maximum mint amount");

    presaleMinted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function presaleOGMint(uint256 quantity, bytes32[] calldata proof) external payable callerIsUser {
    uint256 _salePrice = saleConfig.presalePrice;
    uint256 _totalCost = _salePrice * quantity;
    bytes32 senderKeccak = keccak256(abi.encodePacked(msg.sender));

    require(isPrivateSaleOn(), "Presale is not active");
    require(MerkleProof.verify(proof, ogMerkleRoot, senderKeccak), "Not eligible for presale");
    require(msg.value == _totalCost, "Value cannot be lower than total cost");
    require(totalSupply() < presaleSupply, "Presale supply reached, wait for public sale");
    require(totalSupply() + quantity <= presaleSupply, "Cannot mint this many");
    require(presaleMinted[msg.sender] + quantity <= presaleMaxOG, "Reached maximum mint amount");

    presaleMinted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function publicMint(uint256 quantity) external payable callerIsUser {
    uint256 _salePrice = saleConfig.publicSalePrice;
    uint256 _totalCost = _salePrice * quantity;
    
    require(isPublicSaleOn(), "Public sale is not active");
    require(msg.value == _totalCost, "Value cannot be lower than total cost");
    require(totalSupply() < maxSupply, "Max supply reached, collection sold out");
    require(totalSupply() + quantity <= maxSupply, "Cannot mint this many");
    require(publicMinted[msg.sender] + quantity <= publicSaleMax, "Reached maximum mint amount");

    publicMinted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function setupPresaleInfo(uint256 presalePrice, uint256 presaleStartTime, uint256 presaleEndTime) external onlyOwner {
    saleConfig = SaleConfig(presalePrice, presaleStartTime, presaleEndTime, 0, 0);
  }

  function setupPublicSaleInfo(uint256 publicSalePrice, uint256 publicSaleStartTime) external onlyOwner {
    saleConfig = SaleConfig(0, 0, 0, publicSalePrice, publicSaleStartTime);
  }
  
  function isPrivateSaleOn() public view returns (bool) {
    uint256 _salePrice = saleConfig.presalePrice;
    uint256 _saleStartTime = saleConfig.presaleStartTime;
    uint256 _saleEndTime = saleConfig.presaleEndTime;
    return _salePrice != 0 && _saleStartTime != 0 && _saleEndTime != 0 && block.timestamp >= _saleStartTime && block.timestamp <= _saleEndTime;
  }

  function isPublicSaleOn() public view returns (bool) {
    uint256 _salePrice = saleConfig.publicSalePrice;
    uint256 _saleStartTime = saleConfig.publicSaleStartTime;
    return _salePrice != 0 && _saleStartTime != 0 && block.timestamp >= _saleStartTime;
  }

  function setMaxSupply(uint256 _newSupply) external onlyOwner {
    require(totalSupply() <= _newSupply, "Cannot set maxSupply less than totalSupply");
    maxSupply = _newSupply;
  }

  function setMerkleRoot(bytes32 wlMerkleRoot_, bytes32 ogMerkleRoot_) external onlyOwner {
    wlMerkleRoot = wlMerkleRoot_;
    ogMerkleRoot = ogMerkleRoot_;
  }

  function setPresaleMax(uint8 presaleMaxWL_, uint8 presaleMaxOG_) external onlyOwner {
    presaleMaxWL = presaleMaxWL_;
    presaleMaxOG = presaleMaxOG_;
  }

  function setPublicSaleMax(uint8 publicSaleMax_) external onlyOwner {
    publicSaleMax = publicSaleMax_; 
  }

  function isCollectionSoldOut() public view returns (bool) {
    if(totalSupply() == maxSupply) return true; 
    return false;
  }

  function endPublicSale() external onlyOwner {
    require(isPublicSaleOn(), "Public sale is not active");
    saleConfig = SaleConfig(0, 0, 0, 0, 0);
    maxSupply = totalSupply();
  }

  string private _baseTokenURI;

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  
  function _startTokenId() internal view virtual override(ERC721A) returns (uint256) {
      return 1;
  }

  function withdrawFunds() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed to withdraw payment");
    
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }
}