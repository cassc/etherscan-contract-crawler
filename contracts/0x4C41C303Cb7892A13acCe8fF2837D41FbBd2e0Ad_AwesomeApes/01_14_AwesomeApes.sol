// SPDX-License-Identifier: MIT

/*
 * Contract by pr0xy.io
 *  _______  _     _  _______  _______  _______  __   __  _______    _______  _______  _______  _______
 * |   _   || | _ | ||       ||       ||       ||  |_|  ||       |  |   _   ||       ||       ||       |
 * |  |_|  || || || ||    ___||  _____||   _   ||       ||    ___|  |  |_|  ||    _  ||    ___||  _____|
 * |       ||       ||   |___ | |_____ |  | |  ||       ||   |___   |       ||   |_| ||   |___ | |_____
 * |       ||       ||    ___||_____  ||  |_|  ||       ||    ___|  |       ||    ___||    ___||_____  |
 * |   _   ||   _   ||   |___  _____| ||       || ||_|| ||   |___   |   _   ||   |    |   |___  _____| |
 * |__| |__||__| |__||_______||_______||_______||_|   |_||_______|  |__| |__||___|    |_______||_______|
 */

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract AwesomeApes is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // Contract to recieve ETH raised in sales
  address public vault;

  // Control for public sale
  bool public isActive;

  // Control for presale
  bool public isPresaleActive;

  // Used for verification that an address is included in presale
  bytes32 public merkleRoot;

  // Reference to image and metadata storage
  string public baseTokenURI;

  // Amount of ETH required per mint
  uint256 public price;

  // Storage of addresses that have minted with the `presale()` function
  mapping(address => bool) public presaleParticipants;

  // Sets `price` upon deployment
  constructor(uint256 _price) ERC721("AwesomeApes", "AA") {
    setPrice(_price);
  }

  // Override of `_baseURI()` that returns `baseTokenURI`
  function _baseURI() internal view virtual override returns (string memory) {
    return baseTokenURI;
  }

  // Sets `isActive` to turn on/off minting in `mint()`
  function setActive(bool _isActive) external onlyOwner {
    isActive = _isActive;
  }

  // Sets `merkleRoot` to be used in `presale()`
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  // Sets `baseTokenURI` to be returned by `_baseURI()`
  function setBaseTokenURI(string calldata _baseTokenURI) external onlyOwner {
    baseTokenURI = _baseTokenURI;
  }

  // Sets `isPresaleActive` to turn on/off minting in `presale()`
  function setPresaleActive(bool _isPresaleActive) external onlyOwner {
    isPresaleActive = _isPresaleActive;
  }

  // Sets `price` to be used in `presale()` and `mint()` (called on deployment)
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  // Sets `vault` to recieve ETH from sales and used within `withdraw()`
  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }

  // Minting function used in the gifting process
  function gift(address to, uint256 _amount) external onlyOwner {
    uint256 supply = totalSupply();

    require(supply + _amount < 10001, 'Supply Denied');

    for(uint256 i; i < _amount; i++){
      _safeMint( to, supply + i );
    }
  }

  // Minting function used in the presale
  function presale(bytes32[] calldata _merkleProof, uint256 _amount) external payable {
    uint256 supply = totalSupply();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(_amount < 4, 'Amount Denied');
    require(isPresaleActive, 'Not Active');
    require(supply + _amount < 10001, 'Supply Denied');
    require(tx.origin == msg.sender, 'Contract Denied');
    require(!presaleParticipants[msg.sender], 'Mint Claimed');
    require(msg.value >= price * _amount, 'Ether Amount Denied');
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

    for(uint256 i; i < _amount; i++){
      _safeMint( msg.sender, supply + i );
    }

    presaleParticipants[msg.sender] = true;
  }

  // Minting function used in the public sale
  function mint(uint256 _amount) external payable {
    uint256 supply = totalSupply();

    require(isActive, 'Not Active');
    require(_amount < 6, 'Amount Denied');
    require(supply + _amount < 10001, 'Supply Denied');
    require(tx.origin == msg.sender, 'Contract Denied');
    require(msg.value >= price * _amount, 'Ether Amount Denied');

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