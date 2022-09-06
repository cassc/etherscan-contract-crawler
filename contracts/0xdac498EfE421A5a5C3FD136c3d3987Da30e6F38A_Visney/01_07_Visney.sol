// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";


contract Visney is Ownable, ERC721A {
  using Strings for uint256;

  string public uriBase;
  string public uriExtension;
  string public hiddenMetadataUri;
  
  uint256 public collectionSize = 3000;
  uint256 public maxMint;
  uint256 public publicCost;
  uint256 public allowlistCost;

  bool public paused;
  bool public revealed;
  bool public mintAllowlist;
  bool public teamMinted;

  bytes32 public merkleRoot;

  mapping(address => uint256) public allowlist;

  constructor() ERC721A("Visney", "VIN") {
    setHiddenMetadataUri("");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(tx.origin == msg.sender, "The caller is another contract");
    require(totalSupply() + _mintAmount <= collectionSize, "Reached max supply");
    require(_mintAmount > 0 && _mintAmount <= maxMint, "Invalid mint amount");
    require(!paused, "The contract is paused");
    _;
  }

function allowlistMint(uint256 _mintAmount, bytes32[] memory _merkleProof) public payable mintCompliance(_mintAmount) {
    require(msg.value >= allowlistCost * _mintAmount, "Insufficient funds");
    require(mintAllowlist, "The allowlist mint has ended");
    require(maxMint >= allowlist[msg.sender] + _mintAmount, "Cannot mint this many");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof");

    allowlist[msg.sender] = allowlist[msg.sender] + _mintAmount;
    _safeMint(msg.sender, _mintAmount);
  }

  function publicMint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(msg.value >= publicCost * _mintAmount, "Insufficient funds");
    require(!mintAllowlist, "The public mint has not started");

    _safeMint(msg.sender, _mintAmount);
  }
  
  function teamMint() external onlyOwner {
        require(!teamMinted, "Team already minted");
        teamMinted = true;
        _safeMint(msg.sender, 60);
    }

  function isAllowed(address _address) public view returns (uint256) {
      return allowlist[_address];
  }

  function walletOfOwner(address _owner) public view returns (uint256[] memory) {

    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= collectionSize) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId+1;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {

    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (revealed == false) {
      return hiddenMetadataUri;
    }

   string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriExtension))
        : "";
  }

  function setMintAllowlist(bool _state) public onlyOwner {
    mintAllowlist = _state;
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setPublicCost(uint256 _publicCost) public onlyOwner {
    publicCost = _publicCost;
  }

  function setAllowlistCost(uint256 _allowlistCost) public onlyOwner {
    allowlistCost = _allowlistCost;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMint = _maxMintAmount;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriBase(string memory _uriBase) public onlyOwner {
    uriBase = _uriBase;
  }

  function setUriExtension(string memory _uriExtension) public onlyOwner {
    uriExtension = _uriExtension;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriBase;
  }
}