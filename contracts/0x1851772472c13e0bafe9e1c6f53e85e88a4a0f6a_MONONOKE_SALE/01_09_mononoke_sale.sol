//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract MONONOKE_SALE is ReentrancyGuard, Ownable {
  address public contractAddress;
  uint256 public prePrice = 0.02 ether;
  uint256 public pubPrice = 0.02 ether;
  uint256 public startId = 80;
  uint256 public endId = 139;
  uint256 public mintId = 80;
  bytes32 public merkleRoot;

  mapping(uint256 => uint256) public mintLimit; // _mintType 0: preSale, 1: publicSale
  mapping(uint256 => bool) public saleStart; // _mintType 0: preSale, 1: publicSale
  mapping(address => mapping(uint256 => uint256)) public claimed; // address => (mintType => quantity)

  constructor() {
    mintLimit[0] = 1;
    mintLimit[1] = 5;
  }

  function setContractAddress(address _contractAddress) external onlyOwner {
    contractAddress = _contractAddress;
  }

  function setStartId(uint256 _startId) external onlyOwner {
    startId = _startId;
  }

  function setEndId(uint256 _endId) external onlyOwner {
    endId = _endId;
  }

  function setPrePrice(uint256 _priceInWei) external onlyOwner {
    prePrice = _priceInWei;
  }

  function setPubPrice(uint256 _priceInWei) external onlyOwner {
    pubPrice = _priceInWei;
  }

  function setMintLimit(uint256 _mintType, uint256 _amount) external onlyOwner {
    mintLimit[_mintType] = _amount;
  }

  function setSaleStart(uint256 _mintType, bool _state) external onlyOwner {
    saleStart[_mintType] = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function checkMerkleProof(
    bytes32[] calldata _merkleProof
  ) public view returns (bool) {
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    return MerkleProof.verifyCalldata(_merkleProof, merkleRoot, leaf);
  }

  function preMint(
    uint256 _quantity,
    bytes32[] calldata _merkleProof
  ) external payable nonReentrant {
    uint256 cost = prePrice * _quantity;
    uint256 mintType = 0;
    require(saleStart[mintType], 'Before sale begin.');
    require(_quantity > 0, 'Please set quantity.');
    require(_quantity <= mintLimit[mintType], 'mintLimit over.');
    require(endId > mintId, 'Sold out.');
    require(msg.value == cost, 'Not enough funds');
    require(
      claimed[msg.sender][mintType] < mintLimit[mintType],
      'Already claimed max'
    );
    require(checkMerkleProof(_merkleProof), 'Invalid Merkle Proof');

    claimed[msg.sender][mintType] += _quantity;
    uint256 target = mintId;
    for (uint256 i = 0; i < _quantity; ) {
      IERC721(contractAddress).transferFrom(owner(), msg.sender, target);
      unchecked {
        target++;
        i++;
      }
    }

    mintId += _quantity;
  }

  function pubMint(uint256 _quantity) external payable nonReentrant {
    uint256 cost = prePrice * _quantity;
    uint256 mintType = 1;
    require(saleStart[mintType], 'Before sale begin.');
    require(_quantity > 0, 'Please set quantity.');
    require(_quantity <= mintLimit[mintType], 'mintLimit over.');
    require(endId > mintId, 'Sold out.');
    require(msg.value == cost, 'Not enough funds');
    require(
      claimed[msg.sender][mintType] < mintLimit[mintType],
      'Already claimed max'
    );

    claimed[msg.sender][mintType] += _quantity;
    uint256 target = mintId;
    for (uint256 i = 0; i < _quantity; ) {
      IERC721(contractAddress).transferFrom(owner(), msg.sender, target);
      unchecked {
        target++;
        i++;
      }
    }
    mintId += _quantity;
  }

  struct ProjectMember {
    address founder;
    address dev;
  }
  ProjectMember private _member;

  function setMemberAddress(address _founder, address _dev) public onlyOwner {
    _member.founder = _founder;
    _member.dev = _dev;
  }

  function withdraw() external onlyOwner {
    require(
      _member.founder != address(0) && _member.dev != address(0),
      'Please set member address'
    );

    uint256 balance = address(this).balance;
    Address.sendValue(payable(_member.founder), ((balance * 6000) / 10000));
    Address.sendValue(payable(_member.dev), ((balance * 4000) / 10000));
  }
}