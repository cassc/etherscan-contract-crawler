// SPDX-License-Identifier: UNLICENSED
/*
******************************************************************
                 
                 Genesis Goats

******************************************************************
                  Developed by Meraj khalid
*/
       
pragma solidity ^0.8.0;
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Genesis_Goats is ERC721A, Ownable {
  using Strings for uint256;

  constructor() ERC721A("Genesis Goats", "GG")  {}

  //URI uriPrefix is the BaseURI
  string public uriPrefix = "ipfs://QmVDQXWAXYnWgGXQBXqLnpPZQyCizBvAzGi4m1jKAyHu3V/";
  string public uriSuffix = ".json";
  
  uint256 public maxSupply = 777;
  uint256 public cost = 0.07 ether;
  uint256 public maxMintAmount = 2;
  bool public MintStarted = true;
 
  modifier mintCompliance(uint256 _mintAmount) {
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(MintStarted, "The contract is paused!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");
      require(_numberMinted(msg.sender) + _mintAmount <= maxMintAmount , "Exceeds Max mint!");
    _safeMint(msg.sender, _mintAmount);
  }

   function Airdrop(uint256 _mintAmount, address[] memory _receiver) public onlyOwner mintCompliance(_mintAmount){
    for (uint256 i = 0; i < _receiver.length; i++) {
      _safeMint(_receiver[i], _mintAmount);
    }
  }

  function OwnerMint(uint256 _mintAmount) public onlyOwner mintCompliance(_mintAmount){
    _safeMint(msg.sender , _mintAmount);
   }  

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory){
    require(_exists(_tokenId),"ERC721Metadata: URI query for nonexistent token");
    string memory currentBaseURI = _baseURI();
    _tokenId = _tokenId+1;
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
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