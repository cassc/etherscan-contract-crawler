// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "https://github.com/chiru-labs/ERC721A/blob/v4.0.0/contracts/ERC721A.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/access/Ownable.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/security/ReentrancyGuard.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.6.0/contracts/utils/Strings.sol";


contract z00ts is ERC721A, Ownable, ReentrancyGuard {
  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';

  uint256 public cost = 0.0035 ether;
  uint256 public maxSupply = 5555;
  uint256 public maxMintAmount = 20;
  uint256 public maxFreeMintAmount = 1;

  bool public paused = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol
  ) ERC721A(_tokenName, _tokenSymbol) {}

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, "The contract is paused!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(tx.origin == msg.sender, "The caller is another contract");
    require(
      _mintAmount > 0 && numberMinted(msg.sender) + _mintAmount <= maxMintAmount,
       "Invalid mint amount!"
    );
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    int256 costToSubtract = 0;
    if (numberMinted(msg.sender) < maxFreeMintAmount) {
      uint256 freeMintsLeft = maxFreeMintAmount - numberMinted(msg.sender);
      costToSubtract = int256(cost * freeMintsLeft);
    }
   
    int256 finalCost = int256(cost) * int256(_mintAmount) - costToSubtract;
    if (finalCost < 0) {
      finalCost = 0;
    } 

    require(int256(msg.value) >= finalCost, "Insufficient funds!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setMaxFreeMintAmount(uint256 _maxFreeMintAmount) public onlyOwner {
    maxFreeMintAmount = _maxFreeMintAmount;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    uint256 teamMateOne = address(this).balance * 20 / 100;
    uint256 teamMateTwo = address(this).balance * 40 / 100;

    (bool teamMateOneSuccess, ) = payable(0x29Ea87D760b0588e5EF7d917555D46602B72dDc1).call{value: teamMateOne}('');
    require(teamMateOneSuccess);

    (bool teamMateTwoSuccess, ) = payable(0xC189262B1b01862562786487106A6944876B4F05).call{value: teamMateTwo}('');
    require(teamMateTwoSuccess);

    (bool teamMateThreeSuccess, ) = payable(owner()).call{value: address(this).balance}('');
    require(teamMateThreeSuccess);
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}