// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/common/ERC2981.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract SmartContract is ERC721A, ERC2981, Ownable, ReentrancyGuard {

  string public uriPrefix;
  string public uriSuffix;
  string public contractUri;
  string public hiddenMetadataUri;

  uint256 public mintPrice;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerWallet;

  bool public paused;
  bool public revealed;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _uriPrefix,
    string memory _uriSuffix,
    string memory _contractUri,
    string memory _hiddenMetadataUri,
	uint256 _mintPrice,
	uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxMintAmountPerWallet
  )
  ERC721A(_name, _symbol) {
    setUriPrefix(_uriPrefix);
    setUriSuffix(_uriSuffix);
	contractUri = _contractUri;
	setHiddenMetadataUri(_hiddenMetadataUri);
	setMintPrice(_mintPrice);
	maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setMaxMintAmountPerWallet(_maxMintAmountPerWallet);
    _setDefaultRoyalty(msg.sender, 500);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused);
	require(_mintAmount > 0);
    require(tx.origin == msg.sender);
    require(_mintAmount <= maxMintAmountPerTx);
    require(_mintAmount + totalSupply() <= maxSupply);
    require(_mintAmount + _numberMinted(msg.sender) <= maxMintAmountPerWallet);
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= mintPrice * _mintAmount);
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    _mint(msg.sender, _mintAmount);
    (bool os, ) = payable(owner()).call{ value: address(this).balance }('');
	require(os);
  }

  function ownerMint(uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
    _mint(msg.sender, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId));
	string memory baseUri = _baseURI();
    if (revealed == true) {
	  return string(abi.encodePacked(hiddenMetadataUri));
	}
	else {
      return bytes(baseUri).length > 0 ?
	  string(abi.encodePacked(baseUri, '/', _toString(_tokenId), uriSuffix)) : '';
	}
  }

  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(contractUri));
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

  function setMintPrice(uint256 _mintPrice) public onlyOwner {
    mintPrice = _mintPrice;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxMintAmountPerWallet(uint256 _maxMintAmountPerWallet) public onlyOwner {
    maxMintAmountPerWallet = _maxMintAmountPerWallet;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function withdrawFunds() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{ value: address(this).balance }('');
	require(os);
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
}