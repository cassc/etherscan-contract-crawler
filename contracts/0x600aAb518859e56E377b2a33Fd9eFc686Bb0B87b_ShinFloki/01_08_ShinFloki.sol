// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract ShinFloki is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => uint256) public Counter;
  


  string public uriPrefix = 'ipfs://bafybeih2xgh2gc4wgqzgafqxkkxiodouuaensbhivbhgesudb3o4f6rxue/';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost1 = 0 ether;
  uint256 public cost2 = 0.003 ether;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerW;

  bool public paused = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerW,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    _safeMint(msg.sender, 50);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerW(_maxMintAmountPerW);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  function calculatePrice() public view returns (uint256) {
        require(paused == false, "Sale hasn't started");
        require(totalSupply() < maxSupply, "Sale has already ended");
        uint currentSupply = totalSupply();
        if (currentSupply >= 4500) {
            return cost2;
        } else {
            return cost1;
        }
    }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }


  function mint(uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmountPerTx);
    require(supply + _mintAmount <= maxSupply);
    require(
        Counter[_msgSender()] + _mintAmount <= maxMintAmountPerW,
        "exceeds max per address"
        );
      require(totalSupply() + _mintAmount <= maxSupply, "reached Max Supply");
      
      Counter[_msgSender()] = Counter[_msgSender()] + _mintAmount;
    if (msg.sender != owner()) {
      require(msg.value >= calculatePrice() * _mintAmount);
    }

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setcost1(uint256 _cost1) public onlyOwner {
    cost1 = _cost1;
  }  

  function setcost2(uint256 _cost2) public onlyOwner {
    cost2 = _cost2;
  }
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
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

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setMaxMintAmountPerW(uint256 _maxMintAmountPerW) public onlyOwner {
      maxMintAmountPerW = _maxMintAmountPerW;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}