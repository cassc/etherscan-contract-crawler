// SPDX-License-Identifier: GPL-3.0


pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract TwistedGoblinNFT is ERC721, Ownable {

  string public baseURI;
  string public notRevealedUri;
  uint256 public cost;
  uint256 public totalSupply;
  uint256 public maxSupply;
  uint256 public maxPerWallet;
  bool public paused;
  bool public revealed;
  mapping(address => uint256) public addressMintedBalance;

  constructor(string memory _initNotRevealedUri) ERC721("Twisted Goblin", "TG") {
    cost = 0.005 ether;
    maxSupply = 10000;
    maxPerWallet = 3;
    paused = false;
    revealed = false;
    notRevealedUri = _initNotRevealedUri;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }


  function premint(uint256 _mintAmount) external payable onlyOwner {
      for(uint256 i = 0; i < _mintAmount; i++){
            uint256 newTokenID = totalSupply + 1;
            totalSupply ++;
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, newTokenID);
        }
    }
  // public
  function mint(uint256 _mintAmount) public payable {
    require(!paused, "the contract is paused");
    require(addressMintedBalance[msg.sender] + _mintAmount <= maxPerWallet,'exceed max per wallet');
    require(totalSupply + _mintAmount <= maxSupply, "max NFT limit exceeded");

    //first mint is free
    uint256 totalPrice = _mintAmount * cost;
    if (addressMintedBalance[msg.sender] == 0){
        totalPrice = totalPrice - cost;
        }
    require(msg.value >= totalPrice, "insufficient funds");

    for (uint256 i = 1; i <= _mintAmount; i++) {
      uint256 newTokenID = totalSupply + 1;
      totalSupply++;
      addressMintedBalance[msg.sender]++;
      _safeMint(msg.sender, newTokenID);
    }
  }


  function tokenURI(uint256 tokenId) public view override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, Strings.toString(tokenId), ".json"))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
      revealed = true;
  }
  
  function setmaxPerWallet(uint256 _limit) public onlyOwner {
    maxPerWallet = _limit;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
 
  function withdraw() public payable onlyOwner {
    (bool sucess, ) = payable(owner()).call{value: address(this).balance}("");
    require(sucess,'withdraw failed');
  }
}