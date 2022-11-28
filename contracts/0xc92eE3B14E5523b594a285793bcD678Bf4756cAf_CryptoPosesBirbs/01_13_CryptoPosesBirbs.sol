// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '../DefaultOperatorFilterer.sol';

contract CryptoPosesBirbs is ERC721AQueryable, Ownable, ReentrancyGuard,DefaultOperatorFilterer {

  using Strings for uint256;

  string public uriPrefix;
  string public uriSuffix = '';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.0009 ether;
  uint256 public maxSupply =3333;
  uint256 public maxMintAmountPerTx = 25;
  uint256 public maxFreeAmountPerTx = 2;
  uint256 public maxPerWallet = 50;
  uint256 public maxFreePerWallet = 2;
  

  bool public paused = false;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _initUriPrefix
  ) ERC721A(_tokenName, _tokenSymbol) {
    setUriPrefix (_initUriPrefix);
    
  }
  modifier mintFreeCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxFreeAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(_numberMinted(msg.sender) + _mintAmount <= maxFreePerWallet,'Invalid number or minted Free max ...');
    require(tx.origin == msg.sender, 'Contract minters gets no apesons...');
    _;
  }

  function freeMint(uint256 _mintAmount) public payable mintFreeCompliance(_mintAmount) {
      require(msg.value == 0, 'Put 0 in');
      require(!paused, 'The contract is paused!');
      _safeMint(_msgSender(), _mintAmount);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(_numberMinted(msg.sender) + _mintAmount <= maxPerWallet,'Invalid number or minted max ...');
    require(tx.origin == msg.sender, 'Contract minters gets no apesons...');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }


  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override (IERC721A, ERC721A) returns (string memory) {
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

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxFreePerWallet (uint256 _maxFreePerWallet) public  onlyOwner {
    maxFreePerWallet = _maxFreePerWallet;
  }

  function setMaxFreeAmountPerTx (uint256 _maxFreeAmountPerTx) public onlyOwner{
    maxFreeAmountPerTx = _maxFreeAmountPerTx;
  }

  


  function setmaxPerWallet (uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
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

 // OperatorFilter overrides
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public payable override(IERC721A, ERC721A) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }



  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}