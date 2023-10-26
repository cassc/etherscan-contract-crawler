// SPDX-License-Identifier: GPL-3.0
// Author: Pagzi Tech Inc. | 2021
pragma solidity ^0.8.10;
import "./pagzi/ERC721Enum.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract MetaMobs is ERC721Enum, Ownable, PaymentSplitter, ReentrancyGuard {
  using Strings for uint256;
  string public baseURI;
  uint256 public cost = 0.045 ether;
  uint256 public maxMobs = 3333;
  uint256 public maxMint = 50;
  bool public paused = false;
  mapping(address => bool) public whitelisted;
  address[] private addressList = [
    0x2d0F4bcD4D2f08FAbD5a9e6Ed7c7eE86aFC3B73f,
    0x723eC21b513b9cc7c9ED7838e10d640de0b9d0fa
  ];
  uint[] private shareList = [25,75];

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721P(_name, _symbol)
    PaymentSplitter( addressList, shareList ){
    setBaseURI(_initBaseURI);
    mint(msg.sender, 25);
  }

  // internal
  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable nonReentrant{
    uint256 s = totalSupply();
    require(!paused, "1" );
    require(_mintAmount > 0, "2" );
    require(_mintAmount <= maxMint, "3" );
    require(s + _mintAmount <= maxMobs, "4" );

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount);
        }
    }

    for (uint256 i = 0; i < _mintAmount; ++i) {
      _safeMint(_to, s + i, "");
    }
  }

  function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Provide quantities and recipients" );

    uint totalQuantity = 0;
    uint256 s = totalSupply();
    for(uint i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( s + totalQuantity <= maxMobs, "Too many" );
    delete totalQuantity;

    for(uint i = 0; i < recipient.length; ++i){
      for(uint j = 0; j < quantity[i]; ++j){
        _safeMint( recipient[i], s++, "" );
      }
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
      "ERC721Metadata: Nonexistent token"
    );

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString()))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setMaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMint = _newmaxMintAmount;
  }
  
  function setMaxMobs(uint256 _newMaxMobs) public onlyOwner {
    maxMobs = _newMaxMobs;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistMob(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWLMob(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}