// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Sp00keeOnez is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerAddress;
  mapping(address => uint256) public mintedAmountByAddress;
  uint256 public freeOGMints;
  mapping(address => bool) public ogClaimed;


  bool public paused = true;
  bool public ogMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerAddress,
    string memory _hiddenMetadataUri,
    uint256 _freeOGMints
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    setMaxSupply(_maxSupply);
    setMaxMintAmountPerAddress(_maxMintAmountPerAddress);
    setHiddenMetadataUri(_hiddenMetadataUri);
    setFreeOGMints(_freeOGMints);
  }

  modifier ogMintCompliance(uint256 _mintAmount) {
    require(ogMintEnabled, 'The OG sale is not enabled!');
    require(!ogClaimed[_msgSender()], 'Address already claimed!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    require(_mintAmount <= freeOGMints, 'Invalid Mint Amount!');
    _;
  }

  modifier teamMintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!paused, 'The contract is paused!');
    require(_mintAmount > 0 && mintedAmountByAddress[_msgSender()] + _mintAmount <= maxMintAmountPerAddress, 'Minted max amount for address!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function ceil(uint a, uint m) internal pure returns (uint ) {
    return ((a + m - 1) / m) * m;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    uint256 _amountPaid = ceil(_mintAmount / 3 * 2, 1);
    uint256 _mintCost = cost * _amountPaid;
    require(msg.value >= _mintCost, 'Insufficient funds!');
    _;
  }

  function ogMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public ogMintCompliance(_mintAmount) nonReentrant {
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    ogClaimed[_msgSender()] = true;

    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) nonReentrant {
    mintedAmountByAddress[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public teamMintCompliance(_mintAmount) onlyOwner {
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

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setFreeOGMints(uint256 _freeOGMints) public onlyOwner {
    freeOGMints = _freeOGMints;
  }

  function setMaxMintAmountPerAddress(uint256 _maxMintAmountPerAddress) public onlyOwner {
    maxMintAmountPerAddress = _maxMintAmountPerAddress;
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

  function setOGMintEnabled(bool _state) public onlyOwner {
    ogMintEnabled = _state;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}