// SPDX-License-Identifier: MIT


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract ChonkSociety is ERC721Enumerable, Ownable {
  using Strings for uint256;
  bytes32 public constant merkleRoot = 0x1c59172521baca45ea5b482a6849c951386a295e51a04b71cd09dd1a515fe8dc;
  string public constant ChonkProvenanceHash = "d1cf92465accb475585dcc0be634baac5da76ef727c38093ac077ca234f90f19"; //keccak256 hash of ipfs images CID, for accountability
  string public constant baseExtension = ".json";
  uint256 public constant publicCost = 0.04 ether;
  uint256 public constant whitelistCost = 0.03 ether;
  uint256 public constant maxTotalSupply = 1501; //one reserved for OG chonk
  uint256 public constant maxPublicSupply = 1111;
  uint256 public constant maxAirdropSupply = 389;
  uint256 public constant maxPerTransaction = 10;
  uint256 public publicAmountMinted = 0;
  uint256 public airdropAmountMinted = 0;
  string public baseURI = "https://chonksociety.s3.us-east-2.amazonaws.com/metadata/";
  bool public paused = false;
  bool public onlyWhitelisted = true;

  constructor() ERC721("Chonk Society", "CHONK") { 
    _safeMint(msg.sender, 0); //OG chonk :)
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function mint(uint256 _mintAmount) external payable {
    require(!paused && !onlyWhitelisted, "Sale closed.");
    require(_mintAmount <= maxPerTransaction, "Exceed max per mint");
    uint256 supply = totalSupply();    
    require(supply < maxTotalSupply, "Out of stock.");
    require(publicAmountMinted + _mintAmount <= maxPublicSupply, "Public mint exceeded");
    require(publicCost * _mintAmount <= msg.value, "Insufficient Eth");
    for(uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
      publicAmountMinted++;
    }
  }


  function whitelistMint(uint256 _mintAmount, bytes32[] calldata merkleProof) external payable {
    require(!paused && onlyWhitelisted, "Whitelist only.");
    require(_mintAmount <= maxPerTransaction, "Exceed max per mint");
    require(balanceOf(msg.sender) == 0, "Only one whitelist transaction allowed");
    //check merkle proof to verify if whitelisted
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(merkleProof, merkleRoot, leaf), "User not on whitelist.");
    uint256 supply = totalSupply();
    require(supply < maxTotalSupply, "Out of stock.");
    require(publicAmountMinted + _mintAmount <= maxPublicSupply, "Public mint exceeded");
    require(whitelistCost * _mintAmount <= msg.value, "Insufficient Eth");
    for(uint256 i = 0; i < _mintAmount; i++) {
      _safeMint(msg.sender, supply + i);
      publicAmountMinted++;
    }
  }

  function airdropMint(address[] calldata _to) external onlyOwner {
    uint256 supply = totalSupply();    
    require(supply < maxTotalSupply, "Out of stock.");
    require(airdropAmountMinted + _to.length <= maxAirdropSupply, "Public mint exceeded");
    for(uint256 i = 0; i < _to.length; i++) {
      _safeMint(_to[i], supply + i);
      airdropAmountMinted++;
    }
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    return string(abi.encodePacked(baseURI, tokenId.toString(), baseExtension));
  }

  //change to ipfs once fully minted
  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}