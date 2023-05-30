// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

contract Sillies is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;
  using SafeMath for uint256; 

  bytes32 public merkleRoot;

  mapping(address => bool) public whitelistClaimed;

  mapping(address => uint) public publicMintedOwner;
  
  string private baseMetadataUri;
  
  uint256 public cost = 0.035 ether;
  uint256 public wlCost = 0.025 ether;
  uint256 public maxSupply = 3333;
  uint256 public maxMintAmountPerTx = 2;
  uint256 public maxWhitelistMintAmountPerTx = 1;
  uint256 public maxPerWallet = 2;

  uint256 public mintsSillyList = 1100;
  uint256 public mintsPublic = 2200;
  
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  
  constructor() ERC721A("Sillies", "Sillies") {}
  
  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount + publicMintedOwner[_msgSender()] <= maxPerWallet);
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(mintsPublic - _mintAmount >= 0, 'Max Public mints exceeded!');
    _;
  }

  modifier mintWhitelistCompliance() {
    require(totalSupply() + 1 <= maxSupply, 'Max supply exceeded!');
    require(mintsSillyList - 1 >= 0, 'Max SillyList mints exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(bytes32[] calldata _merkleProof) public payable mintWhitelistCompliance() {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    whitelistClaimed[_msgSender()] = true;
    mintsSillyList -= 1;
    _safeMint(_msgSender(), 1);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    publicMintedOwner[_msgSender()] += _mintAmount;
    mintsPublic -= _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
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

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }

  function setMxWhitelistMintAmountPerTx(uint256 _maxWhitelistMintAmountPerTx) public onlyOwner {
    maxWhitelistMintAmountPerTx = _maxWhitelistMintAmountPerTx;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMintsSillyList(uint256 _mintsSillyList) public onlyOwner {
    mintsSillyList = _mintsSillyList;
  }

  function setMintsPublic(uint256 _mintsPublic) public onlyOwner {
    mintsPublic = _mintsPublic;
  }

  function setWlCost(uint256 _wlCost) public onlyOwner {
    wlCost = _wlCost;
  }

  function setBaseMetadataUri(string memory _baseMetadataUri) public onlyOwner {
    baseMetadataUri = _baseMetadataUri;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }
}