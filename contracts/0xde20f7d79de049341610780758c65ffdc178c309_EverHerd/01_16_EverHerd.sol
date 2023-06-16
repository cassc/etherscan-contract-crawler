// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

import "./contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";

contract EverHerd is ERC721AQueryable, Ownable, ReentrancyGuard {

 using Strings for uint256;



  string public uriPrefix = "ipfs://QmbkQzEvyYGnr7Zufg5GHasEuiYpcRfLURbJV2w4D7hoQ4/";
  string public uriSuffix = ".json";

  mapping(uint256 => uint256) public cost;
  uint256 public maxSupply;
  uint256 public maxMintAmountPerTx;

  bool public paused = false;



  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    uint256 _maxSupply,
    uint256 _maxMintAmountPerTx
  ) ERC721A(_tokenName, _tokenSymbol) {
    cost[0] = 0.1 ether;
    cost[1] = 0.2 ether;
    cost[2] = 0.4 ether;
    cost[3] = 1.6 ether;
    cost[4] = 5.5 ether;
    maxSupply = _maxSupply;
    setMaxMintAmountPerTx(_maxMintAmountPerTx);
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(totalSupply() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  modifier mintPriceCompliance(uint256 _mintAmount, uint256 _category) {
    require(msg.value >= cost[_category] * _mintAmount, "Insufficient funds!");
    _;
  }

  

  function mint(uint256 _mintAmount,uint256 _category) public payable mintCompliance(_mintAmount) mintPriceCompliance(_mintAmount,_category) {
    require(!paused, "The contract is paused!");

    _safeMint(_msgSender(), _mintAmount,_category);
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver, uint256 _category) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_receiver, _mintAmount, _category);
  }

  function _startTokenId() internal view virtual override returns (uint256) {
    return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenString(_tokenId), uriSuffix))
        : "";
  }

  function tokenString(uint256 _tokenId) view virtual internal returns (string memory){
    if(_tokenId>=1 && _tokenId<10){
        return string(abi.encodePacked("0000",_tokenId.toString()));
    }
    if(_tokenId>=10 && _tokenId<100){
        return string(abi.encodePacked("000",_tokenId.toString()));
    }
    if(_tokenId>=100 && _tokenId<1000){
        return string(abi.encodePacked("00",_tokenId.toString()));
    }
     if(_tokenId>=1000 && _tokenId<=7000){
        return string(abi.encodePacked("0",_tokenId.toString()));
    }

 revert("Invalid token ID");
  }



  function setCost(uint256[] memory _cost) public onlyOwner {
    cost[0] = _cost[0];
    cost[1] = _cost[1];
    cost[2] = _cost[2];
    cost[3] = _cost[3];
    cost[4] = _cost[4];
  }

  function setCost(uint256 _cost, uint256 _category) public onlyOwner {
    cost[_category] = _cost;

  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
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

  function withdraw() public onlyOwner nonReentrant {

    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
   
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}