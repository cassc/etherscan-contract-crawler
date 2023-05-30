// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DangerRanger is ERC721Enumerable, Ownable {
  using Strings for uint256;
  
  string public baseURI;
  string public baseExtension = ".json";
  uint256 public Price = 0.06 ether;
  
  uint256 public maximumSupply = 10670;
  uint256 public maxMintTokens = 20;
  
  bool public paused = false;
  bool public revealed = false;
  bool public publicSale =  false;

  string public notRevealedUri;
  address payable commissions = payable(0x453990006D194f4350fF9F8174Ce1749aB9299D2);
  mapping(address => bool) public whitelisted;
  
  
  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721("Danger Rangers ", "DR-NFT") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public functions
  function mint(uint256 _noOfTokens) public payable {
    uint256 supply = totalSupply();
    require(!paused,"Sale has not started yet.");
    require(_noOfTokens > 0);
    require(_noOfTokens <= maxMintTokens);
    require(supply + _noOfTokens <= maximumSupply);

    //Only whitelisted user is allowed to mint until public sale not started.
    if (msg.sender != owner()) {
      if(whitelisted[msg.sender] != true) {
        require(publicSale,"Sorry, you are not in the eligible whitelist.");
      }
      require(msg.value >= Price * _noOfTokens ,"Not enough ether to purchase NFTs.");
    }


    for (uint256 i = 1; i <= _noOfTokens; i++) {
      if (supply>0)
        _safeMint(msg.sender, supply + i);
      else
        _safeMint(msg.sender, supply);
      
    }
    (bool success, ) = payable(commissions).call{value: msg.value * 25 / 100}("");
    require(success);
    
  }
  

 
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner functions
  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }
  
  function publicSaleStarted(bool _state) public onlyOwner{
    publicSale = _state;
  }

  function setPrice(uint256 _newPrice) public onlyOwner {
    Price = _newPrice;
  }

  function setmaxMintTokens(uint256 _newmaxMintTokens) public onlyOwner {
    maxMintTokens = _newmaxMintTokens;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
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
 
 function whitelistUser(address[] memory _user) public onlyOwner {
    for (uint i = 0; i < _user.length; i++) {
            whitelisted[_user[i]] = true;
        }
  }
 
  function removeWhitelistUser(address _user) public onlyOwner {
    whitelisted[_user] = false;
  }

 function withdraw() public payable onlyOwner {
	     uint balance = address(this).balance;
	     require(balance > 0, "Not enough Ether to withdraw!");
	     (bool success, ) = (msg.sender).call{value: balance}("");
	     require(success, "Transaction failed.");
	}
}