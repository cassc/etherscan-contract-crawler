// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

contract InsidiousPepezOfficial is ERC721AQueryable, Ownable, DefaultOperatorFilterer {

  uint256 public maxSupply;
  uint256 public wlPrice;
  uint256 public publicPrice;
  uint256 public maxWlMint;
  uint256 public maxPublicMint;
  
  using Strings for uint256;
  bytes32 public merkleRoot;
  mapping(address => bool)      public _whitelistClaimed;
  mapping(address => uint256)   public _mintedWallet;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _wlPrice,
    uint256 _publicPrice,
    uint256 _maxSupply,
    uint256 _maxWlMint,
    uint256 _maxPublicMint,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
    setWlPrice(_wlPrice);
    setPublicPrice(_publicPrice);
    maxSupply = _maxSupply;
    setMaxWlMint(_maxWlMint);
    setMaxPublicMint(_maxPublicMint);
    setHiddenMetadataUri(_hiddenMetadataUri);
  }

    function publicMint(uint256 quantity) public payable {
    require(!paused, 'The contract is paused!');
    require(totalSupply() + maxPublicMint <= maxSupply, "Not enough tokens left");
    require(_msgSender() == tx.origin);
    require(_mintedWallet[_msgSender()] + quantity <= maxPublicMint, "Max per wallet reached");
    require(msg.value >= quantity * publicPrice, "Not enough ether sent");
    _safeMint(_msgSender(), quantity);
    _mintedWallet[_msgSender()] += quantity;

  }

    function whitelistMint(uint256 quantity, bytes32[] calldata _merkleProof) public payable {
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    require(!_whitelistClaimed[_msgSender()], 'Address already claimed!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');
    require(totalSupply() + quantity <= maxSupply, "Not enough tokens left");
    require (quantity <= maxWlMint, "invalid mint amount");
    require(msg.value >= quantity * wlPrice, "Not enough ether sent");
    _whitelistClaimed[_msgSender()] = true;
    _safeMint(_msgSender(), quantity);
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

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  
  function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
    return uriPrefix;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }
  
  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setWlPrice(uint256 _wlPrice) public onlyOwner {
    wlPrice = _wlPrice;
  }

  function setPublicPrice(uint256 _publicPrice) public onlyOwner {
    publicPrice = _publicPrice;
  }

    function setMaxWlMint(uint256 _maxWlMint) public onlyOwner {
    maxWlMint = _maxWlMint;
  }

  function setMaxPublicMint(uint256 _maxPublicMint) public onlyOwner {
    maxPublicMint = _maxPublicMint;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
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

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);

  }
}