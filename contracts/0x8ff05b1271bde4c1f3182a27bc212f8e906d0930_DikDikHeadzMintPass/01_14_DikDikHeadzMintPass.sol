// SPDX-License-Identifier: MIT

// Contract by pr0xy.io

pragma solidity ^0.8.7;

import './ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';

contract DikDikHeadzMintPass is ERC721Enumerable, Ownable {
  using Strings for uint256;

  // Contract to recieve ETH raised in sales
  address public vault;

  // Control for public sale
  bool public active;

  // Control for presale
  bool public presaleActive;

  // Used for verification that an address is included in presale
  bytes32 public merkleRoot;

  // Reference to image and metadata storage
  string public uri;

  // Amount of ETH required per mint
  uint256 public price;

  // Storage of addresses that have minted with the `presale` function
  mapping(address => bool) public denylist;

  // Sets `price` upon deployment
  constructor(uint256 _price) ERC721("DikDikHeadzMintPass", "DIKPASS") {
    setPrice(_price);
  }

  // Override of `_baseURI()` that returns `uri`
  function _baseURI() internal view virtual override returns (string memory) {
    return uri;
  }

  // Sets `active` to turn on/off minting in `mint()`
  function setActive(bool _active) external onlyOwner {
    active = _active;
  }

  // Sets `presaleActive` to turn on/off minting in `presale()`
  function setPresaleActive(bool _presaleActive) external onlyOwner {
    presaleActive = _presaleActive;
  }

  // Sets `merkleRoot` to be used in `presale()`
  function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
    merkleRoot = _merkleRoot;
  }

  // Set `price` to be used in `mint()` (called on deployment)
  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  // Sets `uri` to be returned by `_baseURI()`
  function setURI(string memory _uri) external onlyOwner {
    uri = _uri;
  }

  // Set `vault` to recieve ETH from sales and used within `withdraw()`
  function setVault(address _vault) external onlyOwner {
    vault = _vault;
  }

  // Minting function used in the presale
  function presale(bytes32[] calldata _merkleProof) external payable {
    uint256 supply = totalSupply();
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));

    require(presaleActive, 'Not Active');
    require(supply + 1 < 2501, 'Supply Denied');
    require(!denylist[msg.sender], 'Sender Denied');
    require(msg.value >= price, 'Ether Amount Denied');
    require(tx.origin == msg.sender, 'Contract Denied');
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Proof Invalid');

    _safeMint(msg.sender, supply);
    denylist[msg.sender] = true;
  }

  // Minting function used in the public sale
  function mint(uint256 _amount) external payable {
    uint256 supply = totalSupply();

    require(active, 'Not Active');
    require(supply + _amount < 2501, 'Supply Denied');
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