// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract MainRedPill is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using SafeMath for uint256; 

  bytes32 public merkleRoot;

  mapping(address => uint) public publicMintedOwner;
  mapping(uint => uint) public evolutionLevel;
  
  string private baseMetadataUri;
  
  uint256 public cost = 0.039 ether;
  uint256 public maxSupply = 1000;
  uint256 public maxMintAmountPerTx = 1;
  uint256 public maxPerWallet = 1;

  uint256 public maxEvolution = 2;

  bool public paused = true;

  address public pillContract;
  
  constructor() ERC721A("MainRedPill", "MainRedPill") {}
  
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount + publicMintedOwner[_msgSender()] <= maxPerWallet);
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier onlyPillContract {
    require(msg.sender == pillContract);
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    require(totalSupply() + 1 <= maxSupply, 'Max supply exceeded!');
    publicMintedOwner[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function evolveFromPill(uint256 _tokenId) external onlyPillContract {
    require(evolutionLevel[_tokenId] < maxEvolution, 'max pills');
    evolutionLevel[_tokenId] += 1;
  }

  function evolveOverride(uint256 _tokenId, uint256 level) external onlyOwner {
    //  BACKUP safety net
    evolutionLevel[_tokenId] = level;
  }

  function getOwnerOfMain(uint256 _tokenId) external returns (address owner) {
    return ownerOf(_tokenId);
  }

  function getEvolutionLevel(uint256 _tokenId) external view returns (uint256 level) {
    return evolutionLevel[_tokenId];
  }
  
  function teamMint(uint256 _teamAmount) external onlyOwner  {
    require(totalSupply() + _teamAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_msgSender(), _teamAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }
  
  function _baseURI() internal view override returns (string memory) {
    return baseMetadataUri;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setPillAddress(address _pillContract) public onlyOwner {
    pillContract = _pillContract;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxEvolution(uint256 _maxEvolution) public onlyOwner {
    maxEvolution = _maxEvolution;
  }

  function setBaseMetadataUri(string memory _baseMetadataUri) public onlyOwner {
    baseMetadataUri = _baseMetadataUri;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(0x3E9e085ebBb60398ee68DDd72Ef55079ee5Ffc00).call{value: address(this).balance}('');
    require(os);
  }
}