// SPDX-License-Identifier: GPL-3.0


pragma solidity >=0.7.0 <0.9.0;

import "./Blimpie/ERC721EnumerableLite.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/finance/PaymentSplitter.sol";

contract BitBotSociety is ERC721EnumerableLite, Ownable, PaymentSplitter {
  using Strings for uint256;

  string public baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 0.015 ether;
  uint256 public maxSupply = 9999;
  uint256 public maxMintAmount = 20;
  bool public paused = false;
  mapping(address => bool) public whitelisted;

  address[] private addressList = [
    0x01F0Cd813D71e90B612f622403D76DFb93Aa2fCc,
    0xB7edf3Cbb58ecb74BdE6298294c7AAb339F3cE4a
  ];
  uint[] private shareList = [
    95,
    5
  ];

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI
  ) ERC721B(_name, _symbol)
    PaymentSplitter( addressList, shareList ){
    setBaseURI(_initBaseURI);
    mint(msg.sender, 20);
  }

  // internal
  function _baseURI() internal view virtual returns (string memory) {
    return baseURI;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused, "a" );
    require(_mintAmount > 0, "b" );
    require(_mintAmount <= maxMintAmount, "c" );
    require(supply + _mintAmount <= maxSupply, "d" );

    if (msg.sender != owner()) {
        if(whitelisted[msg.sender] != true) {
          require(msg.value >= cost * _mintAmount);
        }
    }

    for (uint256 i = 0; i < _mintAmount; ++i) {
      _safeMint(_to, supply + i, "");
    }
  }

  function gift(uint[] calldata quantity, address[] calldata recipient) external onlyOwner{
    require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

    uint totalQuantity = 0;
    uint256 supply = totalSupply();
    for(uint i = 0; i < quantity.length; ++i){
      totalQuantity += quantity[i];
    }
    require( supply + totalQuantity <= maxSupply, "Mint/order exceeds supply" );
    delete totalQuantity;

    for(uint i = 0; i < recipient.length; ++i){
      for(uint j = 0; j < quantity[i]; ++j){
        _safeMint( recipient[i], supply++, "" );
      }
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; ++i) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
 function whitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = true;
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

  function withdraw() public payable onlyOwner {
    (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
    require(success);
  }
}