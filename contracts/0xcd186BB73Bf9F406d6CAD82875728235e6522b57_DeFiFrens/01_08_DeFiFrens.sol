// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract DeFiFrens is ERC721A, Ownable, ReentrancyGuard {

  using Strings for uint256;

  string public uriPrefix = '';
  string public uriSuffix = '.json';
  string public hiddenMetadataUri;
 
  uint256 public maxSupply = 5555;
  uint256 public maxPublicMintAmountPerTx = 5; 
  uint256 public maxTeamMintAmountPerWallet = 3; 
  uint256 public maxWhitelistMintAmountPerWallet = 1;

  address constant defiOne = 0x8cCdf543A307CeA0288e1736f8bBf2442ca8Cf9C; 
  address constant defiTwo = 0x96884df3d5280671aD0E51F759F9Ef50C4a3e10E;
  address constant defiThree = 0x2cd98D640F570916Dc19De33dFED43a13f3Fa7f9;
  address constant defiFive = 0x8594d7b16F7E9E20B00c595a8e7Fab23E3626Daf;

  uint256 public publicMintCost = 0.025 ether;
  uint256 public teamMintCost = 0 ether;
  uint256 public whitelistMintCost = 0 ether;

  bytes32 public merkleRoot1;
  bytes32 public merkleRoot2;
  bool public paused = true;
  bool public teamMintEnabled = false;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;

  constructor(
      string memory _tokenName, 
      string memory _tokenSymbol, 
      string memory _hiddenMetadataUri)  ERC721A(_tokenName, _tokenSymbol)  {
    hiddenMetadataUri = _hiddenMetadataUri;       
    ownerClaimed();
   
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function ownerClaimed() internal {
    _mint(defiOne, 25); 
    _mint(defiTwo, 25);
    _mint(defiThree, 5);
    _mint(_msgSender(), 195);
    _mint(defiFive, 863);
  }

  function teamMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    require(teamMintEnabled, 'The team sale is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxTeamMintAmountPerWallet, 'Max limit per wallet!');
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot1, leaf), 'Invalid proof for team member!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount) {
    require(whitelistMintEnabled, 'The whitelist is not enabled!');
    require(_numberMinted(_msgSender()) + _mintAmount <= maxWhitelistMintAmountPerWallet, 'Max limit per wallet!');
   
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    require(MerkleProof.verify(_merkleProof, merkleRoot2, leaf), 'Invalid proof for whitelist!');

    _safeMint(_msgSender(), _mintAmount);
  }

  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) nonReentrant {
    require(!paused, 'The mint is paused!');
    require(msg.value >= publicMintCost * _mintAmount, 'Insufficient funds for public sale!');
    require(_mintAmount <= maxPublicMintAmountPerTx, 'Max limited per Transaction!');
    _safeMint(_msgSender(), _mintAmount);
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

  function setCost(uint256 _cost) public onlyOwner {
    publicMintCost = _cost;
  }

  function setMaxPublicMintAmountPerTx(uint256 _maxPublicMintAmountPerTx) public onlyOwner {
    maxPublicMintAmountPerTx = _maxPublicMintAmountPerTx;
  }

  function setMaxTeamMintAmountPerWallet(uint256 _maxTeamMintAmountPerWallet) public onlyOwner {
    maxTeamMintAmountPerWallet = _maxTeamMintAmountPerWallet;
  }

  function setMaxWhitelistMintAmountPerWallet(uint256 _maxWhitelistMintAmountPerWallet) public onlyOwner {
    maxWhitelistMintAmountPerWallet = _maxWhitelistMintAmountPerWallet;
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

  function setMerkleRoot1(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot1 = _merkleRoot;
  }

  function setMerkleRoot2(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot2 = _merkleRoot;
  }

  function setTeamMintEnabled(bool _state) public onlyOwner {
    teamMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;
  }

  function withdraw() public onlyOwner {
  
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}