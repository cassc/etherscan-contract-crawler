// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract mush is ERC721A, Ownable {
  string public _baseTokenURI;
  string public _notRevealedURI;
  uint256 public ogPrice = 0.04 ether;
  uint256 public allowListPrice = 0.05 ether;
  uint256 public publicMintPrice = 0.06 ether;
  uint256 public MAX_SUPPLY = 10000;
  uint256 private reserveAtATime = 66;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 66;
  uint256 public saleType = 0;
  bytes32 private ogWhitelistMerkleRoot = 0xacd396ee820d0ee8da94e54ed6effb5862c652963affbedbae67d8caf8be5e1a;
  bytes32 private allowWhitelistMerkleRoot = 0xacd396ee820d0ee8da94e54ed6effb5862c652963affbedbae67d8caf8be5e1a;
  address address1 = 0xdEEd7E31a89293ECf7f9665E01fD7CB9C0C7C5b3;
  address address2 = 0x2b6650a6d40f6e8B4B799d7E4b04247695f5Be7b;
  address address3 = 0x8DbE19085da237807dFbeB54cbece2a6620558a8;
  address address4 = 0xde2baE50Cd0CAb8F4EeD3B1cD944223Fe15c4742;
  address address5 = 0xa54A2F4438FC48FeE2B665ae1049fDE34A0C53D8;
  address address6 = 0x23662B347a4F534586321a76Be3AD26a6770cee9;
  address address7 = 0xA4087EA6d1De1Dc9f84A8f8d63657cf4AD456817;
  bool public isReveal = false;
  uint256 start_time;
  uint256 reveal_duration = 93000;

  constructor(string memory baseURI, string memory notRevealedURI) ERC721A("The Mushies by SPC", "mush") {
    setBaseURI(baseURI);
    setNotRevealedURI(notRevealedURI);
    start_time = block.timestamp;
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier revealNft {
    if (start_time + reveal_duration <= block.timestamp) {
      isReveal = true;
    } else {
      isReveal = false;
    }
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function reveal() public onlyAuthorized {
    isReveal = !isReveal;
  }

  function setNotRevealedURI(string memory _notRevealedUri) public onlyAuthorized {
    _notRevealedURI = _notRevealedUri;
  }

  function setNotRevealedDuration(uint256 _duration) external onlyOwner {
    reveal_duration = _duration;
  }

  function setSaleType(uint256 _type) external onlyOwner {
    saleType = _type;
  }

  function setOgPrice(uint256 _price) public onlyAuthorized {
    ogPrice = _price;
  }

  function setAllowListPrice(uint256 _price) public onlyAuthorized {
    allowListPrice = _price;
  }

  function setPublicMintPrice(uint256 _price) public onlyAuthorized {
    publicMintPrice = _price;
  }

  function getCurrentPrice() public view returns (uint256) {
    if (saleType == 1) {
      return ogPrice;
    } else if (saleType == 2) {
      return allowListPrice;
    }
    return publicMintPrice;
  }

  function setBaseURI(string memory baseURI) public onlyAuthorized {
    _baseTokenURI = baseURI;
  }

  function setReserveAtATime(uint256 val) public onlyAuthorized {
    reserveAtATime = val;
  }

  function setMaxReserve(uint256 val) public onlyAuthorized {
    maxReserveCount = val;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setMaxMintSupply(uint256 maxMintSupply) external  onlyAuthorized {
    MAX_SUPPLY = maxMintSupply;
  }

  function setOgWhitelistMerkleRoot(bytes32 merkleRootHash) public onlyAuthorized {
    ogWhitelistMerkleRoot = merkleRootHash;
  }

  function setAllowWhitelistMerkleRoot(bytes32 merkleRootHash) public onlyAuthorized {
    allowWhitelistMerkleRoot = merkleRootHash;
  }

  function reserveNft() public onlyAuthorized {
    require(reservedCount <= maxReserveCount, "Max Reserves taken already!");

     _safeMint(msg.sender, reserveAtATime);
  }

  function batchAirdrop(uint256 _count, address[] calldata addresses) external onlyAuthorized {
    uint256 supply = totalSupply();

    require(supply <= MAX_SUPPLY, "Total supply spent.");
    require(supply + _count <= MAX_SUPPLY, "Total supply exceeded.");

    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      _safeMint(addresses[i],_count);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "Token Id Non-existent");
    if(!isReveal){
      return _notRevealedURI;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId), ".json")) : "";
  }

  function mint(uint256 _count, bytes32[] calldata _merkleProof, address _address) public payable saleIsOpen revealNft {
    uint256 mintIndex = totalSupply();

    if (_address != owner()) {
      require(saleType != 0, "Sale is not active currently.");
      require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
      if (saleType == 1) {
        require(_verifyAddressInOgWhiteList(_merkleProof, _address), "NFT:Sender is not whitelisted.");
        require(msg.value >= ogPrice * _count, "Insufficient ETH amount sent.");
      } else if (saleType == 2) {
        require(_verifyAddressInAllowWhiteList(_merkleProof, _address), "NFT:Sender is not whitelisted.");
        require(msg.value >= allowListPrice * _count, "Insufficient ETH amount sent.");
      } else if (saleType == 3) {
        require(msg.value >= publicMintPrice * _count, "Insufficient ETH amount sent.");
      }
      
      uint256 amount = msg.value;
      payable(address1).transfer(amount * 78 / 100);
      payable(address2).transfer(amount * 4 / 100);
      payable(address3).transfer(amount * 25 / 1000);
      payable(address4).transfer(amount * 5 / 1000);
      payable(address5).transfer(amount * 1 / 100);
      payable(address6).transfer(amount * 4 / 100);
      payable(address7).transfer(amount * 10 / 100);
    }

    _safeMint(_address, _count);
  }

  function _verifyAddressInOgWhiteList(bytes32[] calldata merkleProof, address toAddress) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(toAddress));
    return MerkleProof.verify(merkleProof, ogWhitelistMerkleRoot, leaf);
  }

  function _verifyAddressInAllowWhiteList(bytes32[] calldata merkleProof, address toAddress) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(toAddress));
    return MerkleProof.verify(merkleProof, allowWhitelistMerkleRoot, leaf);
  }
}