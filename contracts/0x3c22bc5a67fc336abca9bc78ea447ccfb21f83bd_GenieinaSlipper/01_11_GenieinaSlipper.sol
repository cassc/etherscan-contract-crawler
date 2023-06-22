// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "operator-filter-registry/src/OperatorFilterer.sol";
 
//        ______           _         _                   _____ ___                      
//       / ____/__  ____  (_)__     (_)___     ____ _   / ___// (_)___  ____  ___  _____
//      / / __/ _ \/ __ \/ / _ \   / / __ \   / __ `/   \__ \/ / / __ \/ __ \/ _ \/ ___/
//     / /_/ /  __/ / / / /  __/  / / / / /  / /_/ /   ___/ / / / /_/ / /_/ /  __/ /    
//     \____/\___/_/ /_/_/\___/  /_/_/ /_/   \__,_/   /____/_/_/ .___/ .___/\___/_/     
//                                  by Nicolas Bets           /_/   /_/                 

contract GenieinaSlipper is ERC721A, Ownable, ReentrancyGuard, OperatorFilterer {

  using StringsUpgradeable for uint256;

  struct Whitelist {
      bytes32 merkleRoot;
      uint256 maxMintQuantity;
  }

  Whitelist[] public presaleWhitelists;
  Whitelist[] public whitelists;

  mapping(address => uint256) public presaleMap;
  mapping(address => uint256) public whitelistMap;

  bool public presaleMintEnabled = false;
  bool public whitelistMintEnabled = false;

  uint256 public cost;

  string public uriPrefix = '';
  string public uriSuffix = '.json';

  bool public paused = true;
  bool public closed = false;

  uint256 public maxSupply = 0;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    string memory _metadataUri
  ) ERC721A(_tokenName, _tokenSymbol) OperatorFilterer(address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6), false) {
    setCost(_cost);
    setUriPrefix(_metadataUri);
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintPriceCompliance(_mintAmount) {
    require(!paused && !closed, 'Mint disabled');
    require(whitelistMintEnabled || presaleMintEnabled, 'The whitelist sale is not enabled!');

    mapping(address => uint256) storage map = whitelistMap;
    Whitelist[] memory wls = whitelists;

    if(presaleMintEnabled){
      map = presaleMap;
      wls = presaleWhitelists;
    }

    uint256 maxMintNumber = getMaxMintNumber(_merkleProof);
    require(maxMintNumber > 0, 'Invalid proof!');
    require(_mintAmount > 0 && (map[_msgSender()] + _mintAmount <= maxMintNumber), 'Invalid mint amount!');

    map[_msgSender()] = map[_msgSender()] + _mintAmount;
    maxSupply = maxSupply + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintPublic(uint256 _mintAmount) public payable mintPriceCompliance(_mintAmount) {
    require(!paused && !closed, 'Mint disabled');
    require(!whitelistMintEnabled && !presaleMintEnabled, 'The whitelist sale is enabled');
    require(_mintAmount > 0 && _mintAmount <= 10, 'Invalid mint amount');
    maxSupply = maxSupply + _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
     maxSupply = maxSupply + _mintAmount;
    _safeMint(_receiver, _mintAmount);
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setPresaleMintEnabled(bool _state) public onlyOwner {
    presaleMintEnabled = _state;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function closeEdition() public onlyOwner {
    closed = true;
  }

  function burnMultiple(uint256[] calldata _tokenIds) public {
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      _burn(_tokenIds[i], true);
    }
    maxSupply = maxSupply - _tokenIds.length;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMerkleRoots(Whitelist[] calldata _presaleWhitelists, Whitelist[] calldata _whitelists) public onlyOwner {
      delete presaleWhitelists;
      delete whitelists;

      for (uint256 i = 0; i < _presaleWhitelists.length; i++) {
        presaleWhitelists.push(Whitelist({merkleRoot: _presaleWhitelists[i].merkleRoot, maxMintQuantity: _presaleWhitelists[i].maxMintQuantity}));
      }

      for (uint256 i = 0; i < _whitelists.length; i++) {
        whitelists.push(Whitelist({merkleRoot: _whitelists[i].merkleRoot, maxMintQuantity: _whitelists[i].maxMintQuantity}));
      }
  }

  function getMaxMintNumber(bytes32[] calldata _merkleProof) public view returns (uint256) {
    if(!presaleMintEnabled && !whitelistMintEnabled){
      return 10;
    }

    Whitelist[] memory _whitelists = whitelists;
    if(presaleMintEnabled){
      _whitelists = presaleWhitelists;
    }

    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));

    for (uint256 i = 0; i < _whitelists.length; i++) {
       if(MerkleProof.verify(_merkleProof, _whitelists[i].merkleRoot, leaf)){
        return _whitelists[i].maxMintQuantity;
       }
    }

    return 0;
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

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

}

// developed by Kanye East