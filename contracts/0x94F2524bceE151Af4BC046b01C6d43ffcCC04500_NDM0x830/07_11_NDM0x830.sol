// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
   
// ███    ██ ██████  ███    ███    ██████  ██   ██  █████  ██████   ██████  
// ████   ██ ██   ██ ████  ████   ██  ████  ██ ██  ██   ██      ██ ██  ████ 
// ██ ██  ██ ██   ██ ██ ████ ██   ██ ██ ██   ███    █████   █████  ██ ██ ██ 
// ██  ██ ██ ██   ██ ██  ██  ██   ████  ██  ██ ██  ██   ██      ██ ████  ██ 
// ██   ████ ██████  ██      ██    ██████  ██   ██  █████  ██████   ██████                                                                       

contract NDM0x830 is ERC721A, Ownable, ReentrancyGuard, OperatorFilterer {

  using StringsUpgradeable for uint256;

  bytes32 public merkleRoot;

  mapping(uint256 => mapping(address => bool)) public claimed;
  uint256 public dropIndex = 0;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmount = 1;

  bool public paused = true;
  bool public whitelistMintEnabled = true;
  bool public closed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setUriPrefix(_metadataUri);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(!closed, 'Contract closed');
    require(!paused, 'Contract paused');
    require(!claimed[dropIndex][_msgSender()], 'Address already minted!');
    require(_mintAmount > 0 && _mintAmount <= maxMintAmount, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

    claimed[dropIndex][_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!whitelistMintEnabled, 'The public sale is not enabled!');
    
    claimed[dropIndex][_msgSender()] = true;
    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    require(!closed, 'Contract closed');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _safeMint(_receiver, _mintAmount);
  }

  function newDrop(uint256 _maxSupply) public onlyOwner {
      require(_maxSupply >= maxSupply, 'Invalid maxSupply');
      require(_maxSupply <= 1000, 'maxSupply is bigger than 1000');
      dropIndex ++;
      maxSupply = _maxSupply;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
      require(_maxMintAmount > 0, 'Invalid maxMintAmount');
      maxMintAmount = _maxMintAmount;
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

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
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

  function closeEdition() public onlyOwner {
    closed = true;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function transferFrom(address from, address to, uint256 tokenId) public payable override onlyAllowedOperator(from){
        super.transferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId)
      public
      payable
      override
      onlyAllowedOperator(from){
      super.safeTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
      public
      payable
      override
      onlyAllowedOperator(from) {
      super.safeTransferFrom(from, to, tokenId, data);
  }
}

// by 0x_wh04m1