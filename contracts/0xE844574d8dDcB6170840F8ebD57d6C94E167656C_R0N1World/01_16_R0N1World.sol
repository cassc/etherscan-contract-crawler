/**************
  R0N1 WORLD
/**************/

// @lisac && @chrishol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./tokens/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract R0N1World is ERC721Enumerable, Ownable, Pausable, ReentrancyGuard {
  /****************************************************
    USAGES
  /****************************************************/
  using Strings for uint256;

  /****************************************************
    IMMUTABLE VARIABLES
  /****************************************************/
  address payable public immutable PAYABLE_ADDRESS_1; // WITHDRAW BALANCE TO
  address payable public immutable PAYABLE_ADDRESS_2; // WITHDRAW BALANCE TO

  /****************************************************
    MUTABLE VARIABLES
  /****************************************************/
  string public baseURI;
  uint256 public price = 0.035 ether;
  bytes32 public merkleRoot;

  uint256 public allowlistSaleStartTimestamp; // 1644192000;
  uint256 public publicSaleStartTimestamp; // 1644235200;

  /****************************************************
    CONSTANTS
  /****************************************************/
  uint256 public constant MAX_SUPPLY = 3500;
  uint256 public constant MAX_PER_MINT = 20;
  uint256 public constant MAX_OWNER_SUPPLY = 50;

  /****************************************************
    STORAGE
  /****************************************************/
  mapping(address => uint256) public allowListTokensMintedByAddress;

  /****************************************************
    CONSTRUCTOR
  /****************************************************/
  constructor(
      string memory _baseURI,
      uint256 _allowlistSaleStartTimestamp,
      uint256 _publicSaleStartTimestamp,
      address payable _payableAddress1,
      address payable _payableAddress2
  ) ERC721(
      "R0N1 World",
      "R0N1"
  ) {
    setBaseURI(_baseURI);

    allowlistSaleStartTimestamp = _allowlistSaleStartTimestamp;
    publicSaleStartTimestamp = _publicSaleStartTimestamp;

    PAYABLE_ADDRESS_1 = payable(_payableAddress1);
    PAYABLE_ADDRESS_2 = payable(_payableAddress2);

    _pause();
  }

  /****************************************************
    PRE-MINTING
  /****************************************************/
  function preMintR0N1(address _to, uint256 _qty) public onlyOwner {
    uint256 currentSupply = totalSupply();

    require(currentSupply + _qty <= MAX_OWNER_SUPPLY, "Not enough left");

    for(uint i = 1; i <= _qty; i++) {
      _mint(_to, currentSupply + i);
    }
  }

  /****************************************************
    MINTING
  /****************************************************/
  function mintR0N1(uint256 _qty) public payable whenNotPaused nonReentrant {
    require(block.timestamp >= publicSaleStartTimestamp, "Sale has not started yet");

    uint256 currentSupply = totalSupply();

    require(price * _qty <= msg.value, "Not enough ether");
    require(_qty <= MAX_PER_MINT, "This number of NFTs cannot be minted");
    require(currentSupply + _qty <= MAX_SUPPLY, "Not enough left");

    for(uint i = 1; i <= _qty; i++) {
      _mint(msg.sender, currentSupply + i);
    }
  }

  function allowListMintR0N1(uint256 _qty, uint _freeMint, bytes32[] calldata _proof) public payable whenNotPaused nonReentrant {
    require(block.timestamp >= allowlistSaleStartTimestamp, "Sale has not started yet");

    uint256 currentSupply = totalSupply();

    uint256 mintedSoFar = allowListTokensMintedByAddress[msg.sender];
    uint256 numFreeMints = 0;
    if (_freeMint > mintedSoFar) {
      numFreeMints = _freeMint - mintedSoFar;
    }
    if (numFreeMints > _qty) {
      numFreeMints = _qty;
    }
    require(price * (_qty - numFreeMints) <= msg.value, "Not enough ether");
    require(_qty <= MAX_PER_MINT, "This number of NFTs cannot be minted");
    require(currentSupply + _qty <= MAX_SUPPLY, "Not enough left");
    require(verifyMerkle(merkleLeaf(msg.sender, _freeMint), _proof), "Invalid Merkle Tree proof supplied");

    require(mintedSoFar + _qty <= MAX_SUPPLY, "Reached wallet cap");
    allowListTokensMintedByAddress[msg.sender] += _qty;

    for(uint i = 1; i <= _qty; i++) {
      _mint(msg.sender, currentSupply + i);
    }
  }

  /****************************************************
    FINANCE
  /****************************************************/
  function withdraw() public onlyOwner {
    PAYABLE_ADDRESS_1.call { value: (address(this).balance * 50) / 100 }("");
    PAYABLE_ADDRESS_2.call { value: address(this).balance }("");
  }

  /****************************************************
    HELPER FUNCTIONS
  /****************************************************/

  /**************************************
    BASEURI
  /**************************************/
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(_tokenId > 0 && _tokenId <= MAX_SUPPLY, "URI requested for invalid token");
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, _tokenId.toString()))
        : baseURI;
  }

  function setBaseURI(string memory _baseURI) public onlyOwner {
    baseURI = _baseURI;
  }

  /**************************************
    SET MUTABLE VARS
  /**************************************/
  function setPrice(uint256 _newPrice) public onlyOwner {
    price = _newPrice;
  }

  function setMerkleRoot(bytes32 _newMerkleRoot) public onlyOwner {
    merkleRoot = _newMerkleRoot;
  }

  function setAllowlistSaleStartTimestamp(uint256 _allowlistSaleStartTimestamp) public onlyOwner {
    allowlistSaleStartTimestamp = _allowlistSaleStartTimestamp;
  }

  function setPublicSaleStartTimestamp(uint256 _publicSaleStartTimestamp) public onlyOwner {
    publicSaleStartTimestamp = _publicSaleStartTimestamp;
  }

  /**************************************
    PLAY AND PAUSE
  /**************************************/
  function pause() public onlyOwner {
    _pause();
  }

  function unpause() public onlyOwner {
    _unpause();
  }

  /**************************************
    MERKLE HELPERS
  /**************************************/
  function merkleLeaf(address _address, uint _freeMint) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_address, _freeMint));
  }

  function verifyMerkle(bytes32 _leaf, bytes32[] calldata _proof) internal view returns (bool) {
    return MerkleProof.verify(_proof, merkleRoot, _leaf);
  }

  receive() external payable {}
}