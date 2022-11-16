// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract LemonadeStand is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer{

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public _initalPrice = 0;
  uint256 public maxFreeAmountPerAddress;
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxMintAmountPerAddress;

  mapping(address => uint256) public mintedAmountByAddress;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx,
    uint256 _maxFreeAmountPerAddress,
    uint256 _maxMintAmountPerAddress,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    setmaxFreeAmountPerAddress(_maxFreeAmountPerAddress);
    setMaxMintAmountPerAddress(_maxMintAmountPerAddress);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(_mintAmount > 0 && mintedAmountByAddress[_msgSender()] + _mintAmount <= maxMintAmountPerAddress, 'Minted max amount for address!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }


  modifier teamMintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 _mintCost = cost * _mintAmount;
    uint256 _freeMintsRemainingForAddress = mintedAmountByAddress[_msgSender()] < maxFreeAmountPerAddress ? maxFreeAmountPerAddress - mintedAmountByAddress[_msgSender()] : 0 ;
    uint256 _freeMintsToDiscount;

    if (_freeMintsRemainingForAddress > 0) {
      _freeMintsToDiscount = _freeMintsRemainingForAddress <= _mintAmount ? _freeMintsRemainingForAddress : _mintAmount;
      _mintCost = _mintCost - (_freeMintsToDiscount * cost) ;
    }

    require(msg.value >= _mintCost, 'Insufficient funds!');
    _;
  }

  function setMaxMintAmountPerAddress(uint256 _maxMintAmountPerAddress) public onlyOwner {
    maxMintAmountPerAddress = _maxMintAmountPerAddress;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    mintedAmountByAddress[_msgSender()] += _mintAmount;

    if (mintedAmountByAddress[_msgSender()] >= maxMintAmountPerAddress) {
      whitelistClaimed[_msgSender()] = true;
    }
    _safeMint(_msgSender(), _mintAmount);
  }


function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The contract is paused!');
    mintedAmountByAddress[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }
  

  function setmaxFreeAmountPerAddress(uint256 _maxFreeAmountPerAddress) public onlyOwner {
    maxFreeAmountPerAddress = _maxFreeAmountPerAddress;
  }

  function setmaxMintAmountPerAddress(uint256 _maxMintAmountPerAddress) public onlyOwner {
    maxMintAmountPerAddress = _maxMintAmountPerAddress;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }


  function mintForAddress(uint256 _mintAmount, address _receiver) public teamMintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721Metadata) returns (string memory) {
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

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function transferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
    super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public override(ERC721A, IERC721) onlyAllowedOperator(from) {
    super.safeTransferFrom(from, to, tokenId, data);
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
    return uriPrefix;
  }
}