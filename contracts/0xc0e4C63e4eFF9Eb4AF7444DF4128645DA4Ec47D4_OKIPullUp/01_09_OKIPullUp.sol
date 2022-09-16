// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import 'erc721a/contracts/ERC721A.sol';
import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract OKIPullUp is ERC721A, Ownable, ReentrancyGuard, ERC721AQueryable {
  using Strings for uint256;
  
  string public uriPrefix = 'ipfs://bafybeiaf5c2e4epi2vapjefx7f55qq6sbcpdrgpjbojuoo7ev3zlex77wq/';
  string public uriSuffix = '.json';
  
  uint256 public EXTRA_MINT_PRICE = 0.0069 ether;
  uint256 public MAX_SUPPLY = 8888;
  uint256 public MAX_MINT = 10;

  bool public paused = false;

  mapping(address => uint256) private _freeMinted;

  constructor() ERC721A("OKIPullUp", "CAPYPULLUP") {}

  function mint(uint256 _mintAmount) public payable {
    unchecked {
      require(!paused, 'The contract is paused!');
      require(totalSupply() + _mintAmount <= MAX_SUPPLY, 'Max supply exceeded!');
      require(_mintAmount > 0 && _mintAmount <= MAX_MINT, 'Invalid mint amount!');

      uint256 freeMintCount = _freeMinted[_msgSender()];
      uint256 extraMintCount = _mintAmount;

      if (freeMintCount < 1) {
        if (_mintAmount > 1) {
          extraMintCount = _mintAmount - 1;
        } else {
          extraMintCount = 0;
        }
        _freeMinted[_msgSender()] = 1;
      }

      require(msg.value >= extraMintCount * EXTRA_MINT_PRICE, 'Insufficient funds!');

      _mint(_msgSender(), _mintAmount);
    }
  }

  function _startTokenId() internal pure override returns (uint256) {
    return 1;
  }

  function freeMintedCount(address owner) external view returns (uint256) {
    return _freeMinted[owner];
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A) returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function collectReserves() external onlyOwner {
    require(totalSupply() == 0, "RESERVES TAKEN");

    _mint(msg.sender, 100);
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

}