// SPDX-License-Identifier: UNLICENSED
/*
******************************************************************
                 
                 Contract KangarooKulture

******************************************************************
                  Developed by Meraj khalid
*/
       
pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract KangarooKulture is ERC721A, Ownable {
  using Strings for uint256;

  constructor() ERC721A("KangarooKulture", "KK")  {}

  //URI uriPrefix is the BaseURI
  string public uriPrefix = "ipfs://QmTosvUtyGDMxoG6xxHj5DxrHcwpujzh2QjkCMkQVWSUL7/";
  string public uriSuffix = ".json";

  // hiddenMetadataUri is the not reveal URI
  string public hiddenMetadataUri= "ipfs://QmWBB7VuS8oegMKBuUCXrKAZMKp9FuEgDYFhsN8nL4JPy5/";
  
  uint256 public maxSupply = 1006;
  uint256 public cost = 0.056 ether;

  bool public MintStarted = true;
  bool public revealed = false;
 
  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(MintStarted, "The contract is paused!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
    _safeMint(msg.sender, _mintAmount);
  }

   function Airdrop(uint256 _mintAmount, address[] memory _receiver) public mintCompliance(_mintAmount) onlyOwner {
    for (uint256 i = 0; i < _receiver.length; i++) {
      _safeMint(_receiver[i], _mintAmount);
    }
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    if (revealed == false) {
      return hiddenMetadataUri;}
    string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function Start_Mint(bool _state) public onlyOwner {
    MintStarted = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}