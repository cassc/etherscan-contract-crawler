// SPDX-License-Identifier: MIT
//█▄░▄█ █▀▀ ▀█▀ ▄▀▄ ▀█▀ █▀▀▄ █▀▀ █▄░█ █▀▄ ▄▀▀ 
//█░█░█ █▀▀ ░█░ █▀█ ░█░ █▐█▀ █▀▀ █░▀█ █░█ ░▀▄ 
//▀░░░▀ ▀▀▀ ░▀░ ▀░▀ ░▀░ ▀░▀▀ ▀▀▀ ▀░░▀ ▀▀░ ▀▀░ 

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract MetaTrendsOfficial is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  mapping(address => uint256) public addressMintedBalance;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  address public withdrawAddress = 0x9048300C9F27563b66CEb0888f5620E3126c0724;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public nftPerAddressLimit = 5;
  uint256 public nftReserved = 500;
  uint256 public maxMintAmountPerTx;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setNftReserved(nftReserved);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + nftReserved + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, 'Max NFT per address exceeded');
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[_msgSender()]++;
    }
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimit, 'Max NFT per address exceeded');
    for (uint256 i = 1; i <= _mintAmount; i++) {
      addressMintedBalance[_msgSender()]++;
    }
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');

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

  function setNftPerAddressLimit(uint256 _nftPerAddressLimit) public onlyOwner {
    nftPerAddressLimit = _nftPerAddressLimit;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setNftReserved(uint256 _nftReserved) public onlyOwner {
    nftReserved = _nftReserved;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setWithdrawAddress(address _withdrawAddress) public onlyOwner{
    withdrawAddress = _withdrawAddress;
  }
  

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool hs, ) = payable(withdrawAddress).call{value: address(this).balance * 50 / 100}('');
    require(hs);

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
  if (revealed == false) {
    return hiddenMetadataUri;
    }
    return uriPrefix;
  }

}