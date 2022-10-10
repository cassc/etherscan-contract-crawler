// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract NFT is ERC721A, Ownable {
  string baseURI;
  string public baseExtension = '.json';
  uint256 public cost = 1 ether;
  uint256 public maxSupply = 999;
  address private _crossmintAddress;
  uint256 public maxMintAmount = 3;
  bool public paused = false;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721A(_name, _symbol) {
    setBaseURI(_initBaseURI);
    _crossmintAddress = 0xdAb1a1854214684acE522439684a145E62505233;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);

    if (msg.sender != owner()) {
      require(msg.value >= cost * _mintAmount);
    }

    _safeMint(msg.sender, _mintAmount);
  }

  function crossmint(address _to, uint256 count) public payable {
    uint256 supply = totalSupply();
    require(msg.value >= cost * count, 'Paid value is not sufficient');
    require(supply + count <= maxSupply, 'No more left');
    require(msg.sender == _crossmintAddress, 'This function is for Crossmint only.');

    _safeMint(_to, count);
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function getCrossmintAddress() external view returns (address) {
    return _crossmintAddress;
  }

  function setCrossmintAddress(address crossmintAddress) external onlyOwner {
    _crossmintAddress = crossmintAddress;
  }

  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }
}