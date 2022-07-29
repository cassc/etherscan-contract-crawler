// SPDX-License-Identifier: MIT
// TheVandalizedBall by Onemizer NFT Contract made by GLHC.eth
// For blockchain solutions contact us. Telegram: @xGL8x

pragma solidity 0.8.15;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TheVandalizedBall is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  mapping(address => bool) public claimed;

  bytes32 public merkleRoot;

  string public uriPrefix = '';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  
  bool public whitelistMintEnabled;
  bool public revealed;
  bool public paused;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri,
    bool _paused,
    bool _whitelistMintEnabled
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setPaused(_paused);
    setWhitelistMintEnabled(_whitelistMintEnabled);
  }

  //Write

  function setRevealed(bool _revealed) public onlyOwner {
    revealed = _revealed;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
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

  function setPaused(bool _paused) public onlyOwner {
    paused = _paused;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _whitelistMintEnabled) public onlyOwner {
    whitelistMintEnabled = _whitelistMintEnabled;
  }

  function mint(uint256 _mintAmount) public payable {
    require(!paused, 'The contract is paused!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(claimed[_msgSender()] == false, 'Address already claimed!');
    require(tx.origin == _msgSender(), 'Contract Denied');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');

    claimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(claimed[_msgSender()] == false, 'Address already claimed!');
      bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    claimed[_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function multiMint(uint256 _mintAmount, address[] memory _multipleReceiver) public onlyOwner{
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
      uint j=0;
      for(j;j<_multipleReceiver.length;j++){
        claimed[_multipleReceiver[j]] = true;
        _safeMint(_multipleReceiver[j], _mintAmount);
      }
  }

  function withdraw() public onlyOwner nonReentrant {
    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  //Read

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

    if (revealed == false) {
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString()))
        : '';
  }

}