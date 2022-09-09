// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract CoolTesters is ERC721AQueryable, Ownable, ReentrancyGuard {

  using Strings for uint256;

  bytes32 public merkleRootWL;
  mapping(address => uint256) public whitelistClaimed;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.048 ether;
  uint256 public maxSupply = 7777;
  uint256 public maxMintAmountPerTx = 5;
  uint256 public maxMintAmountPerTxWL = 4;
  uint256 public maxMintAmountPerTxWLFree = 1;
  uint256 public noFreeNft = 777;

  bool public paused = true;
  bool public whitelistMintEnabled = true;
  bool public revealed = false;

  constructor() ERC721A("COOLTESTERS", "CTS") {
    setHiddenMetadataUri("ipfs://QmNxbkRcgBqHnKQxi6pGHLhZNXLbLSgB86vZ2DQitVSaCY/hidden.json");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _;
  }

  modifier isValidMerkleProof(bytes32[] calldata merkleProof, bytes32 root) {
    require(
        MerkleProof.verify(
            merkleProof,
            root,
            keccak256(abi.encodePacked(_msgSender()))
        ),
        "Address does not exist in list"
    );
    _;
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable isValidMerkleProof(_merkleProof, merkleRootWL) {
    uint256 WLClaimed = whitelistClaimed[_msgSender()];

    require(!paused, "The contract is paused!");
    require(whitelistMintEnabled, "The whitelist sale is not enabled!");    

    if(totalSupply() + _mintAmount > noFreeNft){
      require(WLClaimed + _mintAmount <= maxMintAmountPerTxWL, "max NFT per address exceeded");
      require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    }else{
      require(WLClaimed + _mintAmount <= maxMintAmountPerTxWLFree, "max free NFT per address exceeded");
    }

    whitelistClaimed[_msgSender()] += _mintAmount;
    _safeMint(_msgSender(), _mintAmount);
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(!whitelistMintEnabled, "Whitelist Sale is on");

    _safeMint(_msgSender(), _mintAmount);
  }

  function blub(uint256 _mintAmount) public onlyOwner {
    require(_mintAmount > 0 , "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
 
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

  function setMaxMintAmountPerTxWL(uint256 _maxMintAmountPerTxWL) public onlyOwner {
    maxMintAmountPerTxWL = _maxMintAmountPerTxWL;
  }

  function setMaxMintAmountPerTxWLFree(uint256 _maxMintAmountPerTxWLFree) public onlyOwner {
    maxMintAmountPerTxWLFree = _maxMintAmountPerTxWLFree;
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

  function setMerkleRootWL(bytes32 _merkleRoot) public onlyOwner {
    merkleRootWL = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setNoFreeNft(uint128 _noOfFree) public onlyOwner {
    noFreeNft = _noOfFree;
  }

  function withdraw() public onlyOwner nonReentrant {

    // This will transfer the remaining contract balance to the owner.
    // Do not remove this otherwise you will not be able to withdraw the funds.
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}