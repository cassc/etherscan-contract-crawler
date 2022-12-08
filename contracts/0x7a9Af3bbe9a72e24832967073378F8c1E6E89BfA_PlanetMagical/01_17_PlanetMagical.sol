// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract PlanetMagical  is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  string public BaseURI;
  string public uriSuffix = '.json';
  
  uint256 public cost = 0.0069 ether;
  uint256 public maxSupply = 500;
  uint256 public maxFound = 2;
  mapping(address => uint256) public foundCount;

  constructor() ERC721A("Planet Magical", "PM"){

  }

  modifier foundCompliance(uint256 _foundAmount) {
    require(_foundAmount > 0 && _foundAmount <= maxFound, 'Work oneself out!');
    require(totalSupply() + _foundAmount <= maxSupply, 'End of observation!');
    require((foundCount[msg.sender] + _foundAmount) <= maxFound,"rest!");
    _;
  }

  modifier researchPriceCompliance(uint256 _foundAmount) {
    require(msg.value >= cost * _foundAmount, 'Insufficient funding for research!');
    _;
  }

  function found(uint256 _foundAmount) public payable foundCompliance(_foundAmount) researchPriceCompliance(_foundAmount) {
    foundCount[msg.sender] += _foundAmount;
    _safeMint(_msgSender(), _foundAmount);
  }
  
  function published(uint256 _foundAmount) external onlyOwner {
    _safeMint(msg.sender, _foundAmount);
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'No planets were observed');
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFoundMint(uint256 _maxFound) public onlyOwner {
    maxFound = _maxFound;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setBaseURI(string memory _BaseURI) external onlyOwner {
	  BaseURI = _BaseURI;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return BaseURI;
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
}