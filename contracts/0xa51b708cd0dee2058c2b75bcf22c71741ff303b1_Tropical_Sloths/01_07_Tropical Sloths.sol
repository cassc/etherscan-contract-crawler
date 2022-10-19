// SPDX-License-Identifier: UNLICENSED
/*
******************************************************************
                 
                 Contract Tropical Sloths
  
******************************************************************
                 Developed by Meraj khalid
*/
       
pragma solidity ^0.8.17;

import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Tropical_Sloths is ERC721A, Ownable {
  using Strings for uint256;

  constructor() ERC721A("Tropical Sloths", "NTS")  {}
  //uriprefix is the base URI
  string public uriPrefix = "ipfs://QmcSPgaLH7AXNcFE2eR55QYhD2b1ahEt7dEPd9ufXvhpFD/";
  string public uriSuffix = ".json";
 
  // hiddenMetadataUri is the not reveal URI
  string public hiddenMetadataUri= "ipfs://QmQFXKHcUwo9yXxka5ycm1mr8WLZQ8q6EQSnsgquPFc9Xz/";
  
  //MaxSupply
  uint256 public maxSupply = 12121;
  uint256 public wlSupply = 1221;

  uint256 public cost = 0.63 ether;

 // Cost Prisma
  uint256 public costPrisma = 1.95 ether;

 // Max Mints
  uint256 public maxMintPerTx = 3;
  uint256 public MAxminTPrisma = 2;

  bool public PublicMintStarted = false;
  bool public revealed = false;
  bytes32 public merkleRoot;

  function mintPublic(uint256 _mintAmount) public payable {
   require(PublicMintStarted, "Public mint is not active");
   require(totalSupply() + _mintAmount <= 12021, "Public mint is over");
   require( _mintAmount <= maxMintPerTx , "Exceeds Max mint Per Tx!");
   require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _safeMint(msg.sender, _mintAmount);
  }

  function mintWL(uint256 _mintAmount, bytes32[] memory _merkleProof) public payable {
    require(!PublicMintStarted, "The Whitelist sale is ended!");
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid Merkle Proof." );
    require(totalSupply() + _mintAmount <= wlSupply, "The presale ended!");
    require(_mintAmount <= maxMintPerTx , "Exceeds Max mint Per Tx!");
    require(msg.value >=  cost * _mintAmount, "Insufficient funds!");
    _safeMint(msg.sender, _mintAmount);
  }


// Mint Function Used by CrossMint to Mint for an Address
   function crossmint_Public(uint256 _mintAmount, address _to) public payable {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    require( _mintAmount <= maxMintPerTx , "Exceeds Max mint Per Tx!");
    require(msg.sender == 0xdAb1a1854214684acE522439684a145E62505233,
    "This function is for Crossmint only."  );
    _safeMint(_to, _mintAmount);
  }

  function mintPrisma(uint256 _mintAmount) public payable {
    require(totalSupply() > 12021, "Prisma mint is not active");
    require(_numberMinted(msg.sender) + _mintAmount <= MAxminTPrisma , "Exceeds Per wallet limit!");
    require(msg.value >= costPrisma * _mintAmount, "Insufficient funds!");
    _safeMint(msg.sender, _mintAmount);
  }
  
  
  function Airdrop(uint256 _mintAmount, address[] memory _receiver) public onlyOwner {
    for (uint256 i = 0; i < _receiver.length; i++) {
      _safeMint(_receiver[i], _mintAmount);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    if (revealed == false) { return hiddenMetadataUri;} string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix)) : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
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

  function setcostPrisma(uint256 _costPrisma) public onlyOwner {
    costPrisma = _costPrisma;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setWlSupply(uint256 _wlSupply) public onlyOwner {
    wlSupply = _wlSupply;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}