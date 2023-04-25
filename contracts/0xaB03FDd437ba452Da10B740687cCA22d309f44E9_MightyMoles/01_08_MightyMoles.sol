// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MightyMoles is ERC721A, Ownable {
  string public _baseTokenURI;
  uint256 public whiteListPrice = 0.0085 ether;
  uint256 public publicMintPrice = 0.0095 ether;
  uint256 public MAX_SUPPLY = 3000;
  uint256 private reserveAtATime = 66;
  uint256 private reservedCount = 0;
  uint256 private maxReserveCount = 66;
  uint256 public saleType = 0;
  bytes32 private whitelistMerkleRoot = 0x9f60129147777e7e0a769d5ea568c453a1dc038af00f3ac4802189f186d807a6;
  address address1 = 0x8ADb5fF48cD5BF1d678f080e68e057674550a842;
  address address2 = 0x2b6650a6d40f6e8B4B799d7E4b04247695f5Be7b;

  constructor(string memory baseURI) ERC721A("Mighty Moles", "MM") {
    setBaseURI(baseURI);
  }

  modifier saleIsOpen {
    require(totalSupply() <= MAX_SUPPLY, "Sale has ended.");
    _;
  }

  modifier onlyAuthorized() {
    require(owner() == msg.sender);
    _;
  }

  function setSaleType(uint256 _type) external onlyOwner {
    saleType = _type;
  }

  function setWhiteListPrice(uint256 _price) public onlyAuthorized {
    whiteListPrice = _price;
  }

  function setPublicMintPrice(uint256 _price) public onlyAuthorized {
    publicMintPrice = _price;
  }

  function getCurrentPrice() public view returns (uint256) {
    if ( saleType == 1) {
      return whiteListPrice;
    } else if (saleType == 2) {
      return publicMintPrice;
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

  function setWhitelistMerkleRoot(bytes32 merkleRootHash) public onlyAuthorized {
    whitelistMerkleRoot = merkleRootHash;
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
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0 ? string(abi.encodePacked(currentBaseURI, Strings.toString(_tokenId))) : "";
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function mint(uint256 _count, bytes32[] calldata _merkleProof, address _address) public payable saleIsOpen {
    uint256 mintIndex = totalSupply();

    if (_address != owner()) {
      require(saleType != 0, "Sale is not active currently.");
      require(mintIndex + _count <= MAX_SUPPLY, "Total supply exceeded.");
      if (saleType == 1) {
        require(_verifyAddressInWhiteList(_merkleProof, _address), "NFT:Sender is not whitelisted.");
        require(msg.value >= whiteListPrice * _count, "Insufficient ETH amount sent.");
      } else if (saleType == 2) {
        require(msg.value >= publicMintPrice * _count, "Insufficient ETH amount sent.");
      }
      
      uint256 amount = msg.value;
      payable(address1).transfer(amount * 48 / 100);
      payable(address2).transfer(amount * 2 / 100);
    }

    _safeMint(_address, _count);
  }

  function _verifyAddressInWhiteList(bytes32[] calldata merkleProof, address toAddress) private view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(toAddress));
    return MerkleProof.verify(merkleProof, whitelistMerkleRoot, leaf);
  }
}