// SPDX-License-Identifier: MIT
/*
'''''''''''''''''''@''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''@'''@''''''''@@@''''''''@'''@''''''@@@@@@@@@''@@@@@@@''''''''''''''''''''''''''''''''''''''''''''''''''''''@@@@''''''''''''''''''''''''''''''''''
'''''@@''@@''''''@@@@@''''''@@''@@''''''''@@@@@''''''@@@''''''''''''''''''''''''''''''''''''''''''''''''''''''''@@@@@'''''''''''''''''''''''''''''''''
'''''@@@'@@@'@@@@@@@@@@@@@'@@@'@@@''''''''@@@@@''''''@@''''''''''''''''''''''''''''''''''''''''''''''''''''''''@@@@@@'''''''''''''''''''''''''''''''''
'''''@@@'@@@@'''''''''''''@@@@'@@@''''''''@@@@@''''''@@''''''''''''''''''''''''''''''''''''''''''''''''''''''''@@@@@@'''''''''''''''''''''''''''''''''
'''''@@@@'''''''''''''''''''''@@@@''''''''@@@@@'''''@'''''@@@@@@@@'@@@@'@@@@'''''@@@@'''''@@@@@@''''''''''''''@'@@@@@@''''''@@@@@@@@@'''''@@@@@@@@@@@@
'''@@@''''@@@@@@@'''@@@@@@@'''''@@@'''''''@@@@@''''@''''''''@@@@'''''@@''@@@@''''''@''''@@@@'''@@@'''''''''''@@'@@@@@@'''''''@@@@''@@@@'''@@@'@@@@'@@@
''@@''''''''@@'@''''@@@@@'''''''''@@''''''@@@@@'''@@''''''''@@@@'''''@'''@@@@@'''''@'''@@@@''''@@@@''''''''''@@''@@@@@@''''''@@@@'''@@@@''@'''@@@@''@@
'@@'''''''''@@'@''''@@@@'''''''''''@@'''''@@@@@''@@@@'''''''@@@@'''''@'''@@@@@@''''@'''@@@''''''@@@@'''''''''@'''@@@@@@''''''@@@@'''@@@@''@'''@@@@'''@
'@@'''''''''@@'@'''@@@@''''''''''''@@'''''@@@@@@@@@@@'''''''@@@@'''''@'''@@@@@@@'''@''@@@@''''''@@@@'''''''''@'''@@@@@@''''''@@@@'''@@@@''@'''@@@@'''@
'@@'''''''''@@'@'@@@@'@@'''''''''''@@'''''@@@@@'@@@@@@''''''@@@@'''''@'''@'@@@@@@''@''@@@@''''''@@@@''''''''@@@@@@@@@@@@'''''@@@@'''@@@@''@'''@@@@'''@
'@@'''''''''@@'@''@@@@'@@''''''''''@@'''''@@@@@''@@@@@@'''''@@@@'''''@'''@'''@@@@@'@''@@@@''''''@@@@''''''''@''''''@@@@@@''''@@@@@@@@'''''''''@@@@''''
''@@''''''''@@'@'''''@@'@@''''''''@@''''''@@@@@''@@@@@@@''''@@@@'''''@'''@'''@@@@@@@''@@@@''''''@@@@'''''''@@''''''@@@@@@''''@@@@''@@@@'''''''@@@@''''
''@@''''''''@@'@''''''@@'@@@'''''@@'''''''@@@@@''@@@@@@@''''@@@@'''''@'''@''''@@@@@@''@@@@''''''@@@@'''''''@'''''''@@@@@@''''@@@@''@@@@@''''''@@@@''''
'''@@@''''@@@@@@@''''@@@@@@@@@'@@@''''''''@@@@@''''@@@@@@'''@@@@'''''@'''@'''''@@@@@'''@@@@'''''@@@''''''''@''''''''@@@@@@'''@@@@'''@@@@''''''@@@@''''
'''''@@@@'''''''''''''''''''''@@@@''''''''@@@@@''''@@@@@@'''@@@@'''''@'''@''''''@@@@'''@@@@''''@@@@'''''''@@''''''''@@@@@@'''@@@@'''@@@@''''''@@@@''''
'''''''''@@@@'''''''''''''@@@@''''''''''''@@@@@'''''@@@@@@'''@@@@'''@''''@@''''''@@@''''@@@@'''@@@'''''''@@@''''''''@@@@@@@''@@@@'''@@@@'　'''@@@@''''
'''''''''''''@@@@@@@@@@@@@''''''''''''''@@@@@@@@@''@@@@@@@@''''@@@@@''''@@@@''''''@@'''''''@@@@'''''''''@@@@@''  ''@@@@@@@@''@@@@'''@@@@@'''@@@@@@@@''
''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface balanceOfInterface {
  function balanceOf(address addr) external view returns (
      uint256 holds
  );
}

contract KunoLibertePfpCollection is Ownable, ERC721A, ReentrancyGuard, ERC2981{
    uint256 public tokenCount;
    uint256 private mintPrice = 0.05 ether;
    uint256 public batchSize = 100;
    uint256 public psMintLimit = 10;
    uint256 public _totalSupply = 10000;
    uint256 public currentSupply= 1000;
    bool public saleStart = false;
    mapping(address => uint256) public psMinted; 

    address public royaltyAddress;
    uint96 public royaltyFee = 1000;
    
  constructor(
  ) ERC721A("Kuno Liberte PFP Collection", "KLPC",batchSize, _totalSupply) {
     tokenCount = 0;
  }
  function partnerMint(uint256 quantity, address to) external onlyOwner {
    require(
        (quantity + tokenCount) <= (currentSupply), 
        "too many already minted before patner mint"
    );
    _safeMint(to, quantity);
    tokenCount += quantity;
  }
  function psMint(uint256 quantity) public payable nonReentrant {
    require(psMintLimit >= quantity, "limit over");
    require(psMintLimit >= psMinted[msg.sender] + quantity, "You have no Mint left");
    require(msg.value == mintPrice * quantity, "Value sent is not correct");
    require((quantity + tokenCount) <= (currentSupply), "Sorry. No more NFTs");
    require(saleStart, "Sale Paused");
         
    psMinted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
    tokenCount += quantity;
  }

  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }

  function setCurrentSupply(uint256 newSupply) external onlyOwner {
    require(_totalSupply >= newSupply, "totalSupplyover");
    currentSupply = newSupply;
  }

  function switchSale(bool _state) external onlyOwner {
      saleStart = _state;
  }

  function setPrice(uint256 newPrice) external onlyOwner {
      mintPrice = newPrice;
  }
  function setLimit(uint256 newLimit) external onlyOwner {
      psMintLimit = newLimit;
  }

  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }


  //set Default Royalty._feeNumerator 500 = 5% Royalty
  function setRoyaltyFee(uint96 _feeNumerator) external onlyOwner {
    royaltyFee = _feeNumerator;
    _setDefaultRoyalty(royaltyAddress, royaltyFee);
  }

  //Change the royalty address where royalty payouts are sent
  function setRoyaltyAddress(address _royaltyAddress) external onlyOwner {
    royaltyAddress = _royaltyAddress;
    _setDefaultRoyalty(royaltyAddress, royaltyFee);
  }
  
  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721A, ERC2981) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  //URI
  string public _modeATokenURI;
  string public _modeBTokenURI;
  string public _modeCTokenURI;
  string public _modeDTokenURI;

  //style Map
  mapping(uint256 => uint256) public mapTokenMode;

  //key Project
  address x1_address = 0x83565d91809Ab9c0D4d4d5a74610095264aBa4Ce;
  balanceOfInterface x1_Contract = balanceOfInterface(x1_address);

  //retuen BaseURI.internal.
  function _baseURI(uint256 tokenId) internal view returns (string memory){
    if(mapTokenMode[tokenId] == 1) {
      return _modeATokenURI;
    }
    if(mapTokenMode[tokenId] == 2) {
      return _modeBTokenURI;
    }
    if(mapTokenMode[tokenId] == 3) {
      return _modeCTokenURI;
    }
    if(mapTokenMode[tokenId] == 4) {
      return _modeDTokenURI;
    }
      return _modeATokenURI;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    return string(abi.encodePacked(_baseURI(_tokenId), Strings.toString(_tokenId), ".json"));
  }

  //change mode for holder
  function ModeA(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    mapTokenMode[tokenId] = 1;
  }
  function ModeB(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    mapTokenMode[tokenId] = 2;
  }
  function ModeC(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    mapTokenMode[tokenId] = 3;
  }
  function ModeD(uint256 tokenId) public{
    require(ownerOf(tokenId) == msg.sender, "You are not the holder of this token.");
    require(0<x1_Contract.balanceOf(msg.sender), "You don't have collaboration token.");
    mapTokenMode[tokenId] = 4;
  }
  function ModeChangeByOwner(uint256 tokenId,uint256 modeID) public onlyOwner{
    mapTokenMode[tokenId] = modeID;
  }


  //set URI
  function setModeA_URI(string calldata baseURI) external onlyOwner {
    _modeATokenURI = baseURI;
  }
  function setModeB_URI(string calldata baseURI) external onlyOwner {
    _modeBTokenURI = baseURI;
  }
  function setModeC_URI(string calldata baseURI) external onlyOwner {
    _modeCTokenURI = baseURI;
  }
  function setModeD_URI(string calldata baseURI) external onlyOwner {
    _modeDTokenURI = baseURI;
  }
  //set x address
  function setX1Adress(address c_address) external onlyOwner {
    x1_address = c_address;
  }
}