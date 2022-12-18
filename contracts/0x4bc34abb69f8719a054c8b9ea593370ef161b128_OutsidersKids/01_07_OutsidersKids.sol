// SPDX-License-Identifier: UNLICENSED
/*
******************************************************************
                 
                 Contract Outsiders Kids
  
******************************************************************
                 Developed by Meraj khalid
*/
       
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract OutsidersKids is ERC721A, Ownable {
  using Strings for uint256;

  constructor() ERC721A("Outsiders Kids", "OK")  {}
  //uriprefix is the base URI
  string public uriPrefix = "ipfs://Qmb3QuX4iCA7vKgV8Fm23zJAtYyZ75Z5AvAzFtEk1Lt357/";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  //MaxSuppply
  uint256 public maxSupply = 10000;

  //Cost for Whitelist
   uint256 public WLcost = 0.08 ether;
  //Cost for Public Mint
   uint256 public cost = 0.1 ether;

 // Max Mints
  uint256 public MaxMintPublic = 10;
  uint256 public MaxMintWL = 5;

  bool public PublicMintStarted = false;
  bool public revealed = true;
  bytes32 public merkleRoot = 0x28edfa956cb94ca23854113980635ea4c670f1f09c8c29626d0ee7e8d6de728d;
  
  function mintWL(uint256 _mintAmount, bytes32[] memory _merkleProof) public payable {
    require(!PublicMintStarted, "The Whitelist sale is ended!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof." );
    require(totalSupply() + _mintAmount <= 10000, "The presale ended!");
    require(_numberMinted(msg.sender) + _mintAmount <= MaxMintWL , "Exceeds Per wallet limit!");
    require(msg.value >=  WLcost * _mintAmount, "Insufficient funds!");
    _safeMint(msg.sender, _mintAmount);
  }

  function mintPublic(uint256 _mintAmount) public payable {
   require(PublicMintStarted, "Public mint is not active");
   require(totalSupply() + _mintAmount <= 10000, "Public mint is over");
   require(_numberMinted(msg.sender) + _mintAmount <= MaxMintPublic , "Exceeds Max mint Per Wallet!");
   require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _safeMint(msg.sender, _mintAmount);
  }

   
  function Airdrop(uint256 _mintAmount, address[] memory _receiver) public onlyOwner {
    for (uint256 i = 0; i < _receiver.length; i++) {
      _safeMint(_receiver[i], _mintAmount);
    }
  }

  function reserveMint(uint256 _mintAmount) external onlyOwner() { 
      _safeMint(msg.sender,_mintAmount );
        }
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    if (revealed == false) { return hiddenMetadataUri;} string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
  }

  function StartPublicSale(bool _state) public onlyOwner {
    PublicMintStarted = _state;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setPublicCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setWLCost(uint256 _WLcost) public onlyOwner {
    WLcost = _WLcost;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

   function setMaxMintWL(uint256 _MaxMintWL) public onlyOwner {
    MaxMintWL = _MaxMintWL;
  }

    function setMaxMintPublic(uint256 _MaxMintPublic) public onlyOwner {
    MaxMintPublic = _MaxMintPublic;
  }
  
  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}