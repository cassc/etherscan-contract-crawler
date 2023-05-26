// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/extensions/ERC721AQueryable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import 'operator-filter-registry/src/DefaultOperatorFilterer.sol';

// Errors

error MustMintMoreThanZero();
error ExceedsMaxPerTxn();
error TooManym0mntsinthiswallet();
error PublicSaleIsNotActive();
error MintingTooMany();
error SoldOut();
error NotEnoughETH();
error WhitelistSaleIsNotActive();
error WhitelistAlreadyClaimed();
error InvalidMerkleProof();
error URIQueryForNonexistentToken();
error NewSupplyCannotBeSmallerThanCurrentSupply();


contract M0mnts is ERC721AQueryable, Ownable, ReentrancyGuard, DefaultOperatorFilterer {

  using Strings for uint256;

  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;

  string public uriPrefix = 'https://data.zoomtopia.xyz/m0mnts/metadata/';
  string public uriSuffix = '.json';
  
  uint256 public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;
  uint256 public maxPerWallet = 1;

  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = true;

  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _cost,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    setCost(_cost);
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
    
  }

  //Checks for correct mint data being passed through
  modifier mintCheck(uint256 _mintAmount) {
    if (_mintAmount == 0) revert MustMintMoreThanZero();
    if (_mintAmount > maxMintAmountPerTx) revert ExceedsMaxPerTxn();
    if (totalSupply() + _mintAmount > maxSupply) revert SoldOut();
    if (balanceOf(msg.sender) + _mintAmount > maxPerWallet) revert TooManym0mntsinthiswallet();
    _;
  }

  //Checks for correct mint pricing data being passed through
  modifier mintPriceCheck(uint256 _mintAmount) {
    if (msg.value < cost * _mintAmount) revert NotEnoughETH();
    _;
  }

  //Whitelist minting function
  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCheck(_mintAmount) mintPriceCheck(_mintAmount) {
    // Checks whether the mint is open, whether an address has already claimed, and that they are on the WL
    if (!whitelistMintEnabled) revert WhitelistSaleIsNotActive();
    if (whitelistClaimed[_msgSender()]) revert WhitelistAlreadyClaimed();
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    if (!MerkleProof.verify(_merkleProof, merkleRoot, leaf)) revert InvalidMerkleProof();

    whitelistClaimed[_msgSender()] = true;
    _mint(_msgSender(), _mintAmount);
  }

  //Public minting function
  function mint(uint256 _mintAmount) public payable mintCheck(_mintAmount) mintPriceCheck(_mintAmount) {
    if(paused) revert PublicSaleIsNotActive();

    _mint(_msgSender(), _mintAmount);
  }
  
  //Airdrop function - sends enetered number of NFTs to an address for free. Can only be called by Owner
  function airdrop(uint256 _mintAmount, address _receiver) public onlyOwner {
    _mint(_receiver, _mintAmount);
  }

  //Set token starting ID to 1
  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  //return URI for a token based on whether collection is revealed or not
  function tokenURI(uint256 _tokenId) public view virtual override (ERC721A, IERC721Metadata) returns (string memory) {
    if (!_exists(_tokenId)) revert URIQueryForNonexistentToken();


    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }


  //Change token cost
  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  //Change max amount of tokens per txn
  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  //Change max amount of tokens per wallet
  function setMaxPerWallet(uint256 _maxPerWallet) public onlyOwner {
    maxPerWallet = _maxPerWallet;
  }


  //set revealed URI prefix 
  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  //set revealed URI suffix eg. .json
  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  //Function to pause the contract
  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  //Function to set the Merkleroot hash
  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  //Function to set the WL state
  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  //burn function
  function burn(uint256 tokenId) public onlyOwner {   
        _burn(tokenId);
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

  //Withdraw function
  function withdraw() public onlyOwner nonReentrant {
 
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  //update maxsupply for new weekly drops 
  function addNewDrop(uint256 _newDrop) external onlyOwner {
        if (_newDrop < totalSupply()) revert NewSupplyCannotBeSmallerThanCurrentSupply();
        maxSupply = _newDrop;
  }

  function _baseURI() internal view virtual override(ERC721A) returns (string memory) {
    return uriPrefix;
  }
}