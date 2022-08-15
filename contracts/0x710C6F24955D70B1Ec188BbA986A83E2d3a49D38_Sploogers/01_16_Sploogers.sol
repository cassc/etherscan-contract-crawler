// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9 <0.9.0;

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&@@@@@@@@@@@@@@@@&&&&&@@@@@@@&&&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&&&&&//#&&&&&&@@@@@@@@@/&&&@@@@@@@@@@@@@/////&&&@@@@%//#//&&&@@@@@@@&(/#&&&&@@@@@@@@&&&&&&&&&&%//&&(/#&&&&@@@@@@@@@@@@@@&&(/(&&@@@@@@@
// @@@@@@@@@@@@&//(&&&&@#//(/////&&&&&@@@//&&&@@@@@@@@@@@@///&&//&&&@@////%&//&&&@@@@#/&#&&&&&@@@@@@@@@///////(&&&&&@&//#/(///%&&&@@@@@@@&///(&&@@@@@@@@@
// @@@@@@@@@////&&&&@@@@@//(&&&&/////&&&&//&&&&@@@@@@@@@@///&&&#/(&&@@///%&&&/&&&@@@@//%&&@@@@&&&&&&@@&///&&@@@@@@@@@&//&&&&&&///(&&@@&/////&&@@@@@@@@@@@
// @@@@@@#///&&&&@@@@@@@@//(&&&&&&///#&&&//&&&&@@@@@@@@@@//#&&&(//&&&@///&&&&//&&&@@@//&&&&///////&&&@%///&&&&&&@@@@@&//&&&&&///&&&@@@&(//&&&&&@@@@@@@@@@
// @@@@/////////&&&&&@@@@///&&&////&&&&@@//&&&&@@@@@@@@@@//&&&&//#&&@@///&&&&//%&&@@&//&&&///&&&//#&&@%////////&&@@@@@//(&&//#&&@@@@@@@@&//////&&&&@@@@@@
// @@@@@@@@&&&(////&&&@@@///////&&&&@@@@@//#&&&@@@@@@@@@@//&&&&//%&&@@@//&&&&//&&&@@#//&&&&//&&&%/#&&@&///&&@@@@@@@@@@//////(&&&@@@@@@@@@@@&(///&&&&@@@@@
// @@@@@@@@@@%///&&&&@@@@////%&&&@@@@@@@@///&&&@@&&&&&&@@///&&&//&&&@@@///&&&//&&&@@@///&&&//%&&@(&&&@(///&&&&&&&@@@@(%//&&&&///&&&&@@@@@@@@@&%//(&&@@@@@
// @@@@@&(///&&&&@@@@@@@&///&&@@@@@@@@@@@////////////(&&&@///(///&&&@@@///&(//(&&@@@@@//&&&//&&&@@@@@@@/////////&&@@@@@//#&&@@&%///&&&&@&&#///////@@@@@@@
// @@@@@&//&&&@@@@@@@@@@@///&&@@@@@@@@@@@&///////&&&&@@@@@@////(/&&@@@@@/////&&&&@@@@@@/////&&&@@@@@@@@//////&&@@@@@@@@///&@@@@@@&(//&@&//%&&/////@@@@@@@
// @@@@@@//@@@@@@@@@@@@@@///@@@@@@@@@@@@@@///@@@@@@@@@@@@@@@@@@(/@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@(/@@@@@@@@@@@@@@/#@@@@@@@@@@//(@@@@@@@@(@//@@@@@@@
// @@@@@@///@@@@@@@@@@@@@@//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//@@@@@@@
// @@@@@@@/@@@@@@@@@@@@@@@/@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@//@@@@@@@
// @@@@@@@/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&/@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract Sploogers is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public vipClaimed; // Mapping for VIP List
  mapping(address => uint256) public sploogeListClaimed; // Mapping for sploogelist
  mapping(address => uint256) public publicClaimed; // Mapping for publicClaimed

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxSplooge = 2;
  uint256 public maxPublic = 10;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  bool public vipPhase = true;

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
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, 'Insufficient funds!');
    _;
  }

  /**
     * @dev Enter Splooge cleanup fee: (0.0069 per 1 NFT); Enter amount: (1,2,3,etc.); Enter Merkleproof: Found on offical Minting website.
     */
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    // Verify whitelist requirements
    require(whitelistMintEnabled, 'The whitelist sale is not enabled!');
    if (vipPhase) {
      require(!vipClaimed[_msgSender()], 'Address already claimed VIP sale!');
      vipClaimed[_msgSender()] = true;
    }
    else {
      require(sploogeListClaimed[_msgSender()] + _mintAmount <= maxSplooge, 'Address already claimed or will exceed max ammount!');
      sploogeListClaimed[_msgSender()] += _mintAmount; //incremment amount minted
    }
    
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), 'Invalid proof!');

  
    _safeMint(_msgSender(), _mintAmount);
  }

  /**
     * @dev Enter SploogeCleanup (.0099 per 1 NFT) ; Enter Amount: 1,2,3 etc. [MAX 10 per wallet].
     */
  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, 'The contract is paused!');
    require(publicClaimed[_msgSender()] + _mintAmount <= maxPublic, 'Address already claimed or will exceed max ammount!');
    publicClaimed[_msgSender()] += _mintAmount; //incremment amount minted
    _safeMint(_msgSender(), _mintAmount);
  }

  // Minting function for the Owner 
  function mintOwner(uint256 quantity_) external onlyOwner {
    _safeMint(msg.sender, quantity_);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
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

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setVip(bool _vipPhase) public onlyOwner {
    vipPhase = _vipPhase;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  // Set the max splooge amount per wallet
  function setMaxSplooge(uint256 _maxSplooge) public onlyOwner {
    maxSplooge = _maxSplooge;
  }

  // Set max public tokens per wallet
  function setMaxPublic(uint256 _maxPublic) public onlyOwner {
    maxPublic = _maxPublic;
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

  function withdraw() public onlyOwner nonReentrant {
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}