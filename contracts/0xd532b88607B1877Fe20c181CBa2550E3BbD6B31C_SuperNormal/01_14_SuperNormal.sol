// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract SuperNormal is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // Contract to recieve ETH raised in sales
  address public vault;

  // Control for public sale
  bool public isActive;

  // Control for claim process
  bool public isClaimActive;

  // Control for presale
  bool public isPresaleActive;

  // Used for verification that an address is included in claim process
  bytes32 public claimMerkleRoot;

  // Used for verification that an address is included in public sale
  bytes32 public merkleRoot;

  // Used for verification that an address is included in presale
  bytes32 public presaleMerkleRoot;

  // Reference to image and metadata storage
  string public gallery;

  // Amount of ETH required per mint
  uint256 public price;

  // Storage of addresses that have minted with the `claim()` function
  mapping(address => bool) public claimParticipants;

  // Storage of addresses that have minted with the `presale()` function
  mapping(address => bool) public presaleParticipants;

  // Sets `price` upon deployment
  constructor(uint256 _price) ERC721("SuperNormalbyZipcy", "SUPERNORMAL") {
    setPrice(_price);
  }

  // Override of `_baseURI()` that returns `gallery`
  function _baseURI() internal view virtual override returns (string memory) {
    return gallery;
  }

  // Sets `isActive` to turn on/off minting in `mint()`
  function setActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  // Sets `isClaimActive` to turn on/off minting in `claim()`
  function setClaimActive(bool _isClaimActive) external onlyOwner {
    isClaimActive = _isClaimActive;
  }

  // Sets `claimMerkleRoot` to be used in `presale()`
  function setClaimMerkleRoot(bytes32 _claimMerkleRoot) external onlyOwner {
    claimMerkleRoot = _claimMerkleRoot;
  }

  // Sets `gallery` to be returned by `_baseURI()`
  function setGallery(string calldata _gallery) external onlyOwner {
    gallery = _gallery;
  }

  // Sets `merkleRoot` to be used in `mint()`
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  // Sets `isPresaleActive` to turn on/off minting in `presale()`
  function setPresaleActive(bool _isPresaleActive) external onlyOwner {
    isPresaleActive = _isPresaleActive;
  }

  // Sets `presaleMerkleRoot` to be used in `presale()`
  function setPresaleMerkleRoot(bytes32 _presaleMerkleRoot) external onlyOwner {
    presaleMerkleRoot = _presaleMerkleRoot;
  }

  // Sets `price` to be used in `presale()` and `mint()`(called on deployment)
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  // Sets `vault` to recieve ETH from sales and used within `withdraw()`
  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }

  // Minting function used in the claim process
  function claim(bytes32[] calldata _merkleProof, uint256 _amount) external {
    uint256 supply = totalSupply();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _amount));

    require(isClaimActive, 'Not Active');
    require(supply + _amount < 8889, 'Supply Denied');
    require(tx.origin == msg.sender, 'Contract Denied');
    require(!claimParticipants[msg.sender], 'Mint Claimed');
    require(MerkleProof.verify(_merkleProof, claimMerkleRoot, leaf), 'Proof Invalid');

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }

    claimParticipants[msg.sender] = true;
  }

  // Minting function used in the presale
  function presale(bytes32[] calldata _merkleProof, uint256 _amount) external payable {
    uint256 supply = totalSupply();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(_amount < 3, 'Amount Denied');
    require(isPresaleActive, 'Not Active');
    require(supply + _amount < 8889, 'Supply Denied');
    require(tx.origin == msg.sender, 'Contract Denied');
    require(!presaleParticipants[msg.sender], 'Mint Claimed');
    require(msg.value >= price * _amount, 'Ether Amount Denied');
    require(MerkleProof.verify(_merkleProof, presaleMerkleRoot, leaf), 'Proof Invalid');

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }

    presaleParticipants[msg.sender] = true;
  }

  // Minting function used in the public sale
  function mint(bytes32[] calldata _merkleProof, uint256 _amount) external payable {
    uint256 supply = totalSupply();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(isActive, 'Not Active');
    require(_amount < 11, 'Amount Denied');
    require(supply + _amount < 8889, 'Supply Denied');
    require(tx.origin == msg.sender, 'Contract Denied');
    require(msg.value >= price * _amount, 'Ether Amount Denied');
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }
  }

  // Send balance of contract to address referenced in `vault`
  function withdraw() external payable onlyOwner {
    require(vault != address(0), 'Vault Invalid');
    require(payable(vault).send(address(this).balance));
  }
}