// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Satoshi is ERC721Enumerable, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;
  
  Counters.Counter private supply;

  string public baseURI="";
  
  uint256 public Price = 0.125 ether;
  
  uint256 public maxSupply = 999; 

  uint256 public maxPerMintTokens = 5;
  
  bool public paused = false;
  bool public revealed = false;
  bool public publicSale =  false;
  bool public privateSale = true;
      
  
  string public notRevealedUri;
  mapping(address => bool) public whitelisted;
  mapping(address => uint256) public teamListed;
  event teamTokens(uint256 stid,address minter);
  event mintLog(uint256 scid,address minter);
  
    
  constructor() ERC721("Satoshi's Index", "SATOSHI") {
    setNotRevealedURI("ipfs://Qmf7zvXHrqvKgGyzyP3emcckP9dVAAMb73ZU6JQwrzdzLg/satoshi.json");
    setBaseURI("ipfs://Qmc5k49SZ2jXSSYiYRT7fjaftdzHyx8x4cakRbsVWR9B2y/");
    defineTeams();
    defineWhiteListed();
  }

  function defineTeams() private {

    teamListed[0x38Ab167DEd24b52b9F87F30978255ac6C2AFB9a2]=30;
    teamListed[0xCD38Ddd6ba85C5AD33541403d4d1ff3ca2B01004]=30;
    teamListed[0x77396b5CABd6E3d0B0Ff7AAB949Aa47B5e330439]=30;
    teamListed[0x0bC11d9957bFDAb3Aaec0aF8678aDa68280c6E92]=20;
    
    
  }

    // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  
    function totalSupply() public view override returns (uint256) {
        return supply.current();
    }
  
  // public functions
  function mint(uint256 _noOfTokens) public payable {
    
    require(!paused,"Sale has not started yet.");
    require(_noOfTokens > 0);
    require(supply.current() + _noOfTokens <= maxSupply);

    //Only whitelisted user is allowed to mint until public sale not started.
    if (msg.sender != owner()) {
      
      require(maxPerMintTokens >= balanceOf(msg.sender) +_noOfTokens ,"Not eligible to mint this allocation." ); 
      if(whitelisted[msg.sender] != true) {
        require(publicSale,"Sorry, you are not in the whitelist.");
      }
      require(msg.value >= Price * _noOfTokens ,"Not enough ethers to mint NFTs.");
    }

      for (uint256 i = 1; i <= _noOfTokens; i++) {
        supply.increment();
        _safeMint(msg.sender, supply.current());
        emit mintLog (supply.current(), msg.sender);
      
    }
   
  }

  function PrivateMint(uint256 _noOfTokens) public payable {
    
    require(_noOfTokens > 0);

    require(!paused,"Sale has not started yet.");
    require(_noOfTokens > 0);
    require(supply.current() + _noOfTokens <= maxSupply);
    require(privateSale,"Private sale has not started yet");
    require(teamListed[msg.sender] >= balanceOf(msg.sender) +_noOfTokens ,"Reached maximum allocation" ); 
    
    
      for (uint256 i = 1; i <= _noOfTokens; i++) {
        supply.increment();
         _safeMint(msg.sender, supply.current());
        emit teamTokens (supply.current(), msg.sender);
    }
   
  }
  
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;
        ownedTokenIndex++;
      }
      currentTokenId++;
    }
    return ownedTokenIds;
  }


  
  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
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
    maxPerMintTokens = _newmaxMintTokens;
  } 
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function privateSaleStarted(bool _state) public onlyOwner{
    privateSale = _state;
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

  function defineWhiteListed() private {
    whitelisted[0x320aC7B0384354f448a592b3b9A7E61847f63f6d]=true;
    whitelisted[0x6f3c928c9077737b3ca199fA76a9c6184670600B]=true;
    whitelisted[0x541396a365CE1824E9C470c2a63f20c3106bEd81]=true;
    whitelisted[0xaf6adD2717C155CF329a364009C9339225018c5B]=true;
    whitelisted[0x91C977799a0bEc578316381b6Fb77351e850bFcE]=true;
    whitelisted[0x1C080Ab261B04A989D0936941d4805AD9CBF0A82]=true;
    whitelisted[0x654F18819D710664fA9398119CA6e817BF18d975]=true;
    whitelisted[0xC657971956Ba999bC90cEb7d9d8B1aB7b9a94fEB]=true;
    whitelisted[0x6385455e62a54B4dcE013db26429119f988801BF]=true;
    whitelisted[0xEfcB99Af8f41C1B30b835B41e9728997B1BB3f6C]=true;
    whitelisted[0x78045485dC4AD96F60937DAD4B01B118958761ae]=true;
    whitelisted[0x3d01ab91CFb3C1bF38EbA3B8AbB174e7b758A562]=true;
    whitelisted[0x1D935561Ed16A3B7Fe52B0fA4c14617f09efC78e]=true;
    whitelisted[0x4cdf0AC9d204F559B3c709aa81b7a071476fad92]=true;
    whitelisted[0x3089883e17B205746467A3e12ab31666bbaE2883]=true;
    whitelisted[0x2FDB6e0E20490010f4248Ad97774A00E0CAD01DA]=true;
    whitelisted[0x53daA40e7788999d6b0aFF601aF197Fed5A3759C]=true;
    whitelisted[0x23EE41F656A0A04228A2773721326A77DCE8d63B]=true;
    whitelisted[0x7eB48d59a6302E41733542F4d2f4172d053448b0]=true;
    whitelisted[0x93681a454C6AF6FbAC98C77e120e69De1431D34C]=true;
    whitelisted[0x0eCac2FD4DF99324ebc4936f4B40A42d434B72a1]=true;
    whitelisted[0xA6Afdc478FCAb736C34060B752f7d896386de1f6]=true;
    whitelisted[0xBC3D33556be2a42de98314B60CD11fBec815d985]=true;
    whitelisted[0xC8A7e3cff9e370a7f52D2C34590D7ebdB1d82671]=true;
    whitelisted[0x68884b038F19833eFfD78da059B83a78496E5B05]=true;
    whitelisted[0xd5dbaD939958B0FE6c5087CC87Ba5247109CD958]=true;
    whitelisted[0xB5A70A04c4A4798bFeDF2D43d80af2A2ae2E5319]=true;
    whitelisted[0xc4DaD120712A92117Cc65D46514BE8B49ED846a1]=true;
    whitelisted[0x4cdf0AC9d204F559B3c709aa81b7a071476fad92]=true;
    whitelisted[0xdAA671776166333fDFcD6168bd7c6aC7DD1eD92e]=true;
    whitelisted[0x7E8e8CAd4A0d8d3b13507e06e9364ceeB24997A2]=true;
    whitelisted[0x53daA40e7788999d6b0aFF601aF197Fed5A3759C]=true;
    whitelisted[0x97B4065572357633E9eeF49c25f36Fe25Ed570e8]=true;
    whitelisted[0x88cDC1f6cC7a4497a7F18D6b7A63F9ffEB18EB48]=true;
    whitelisted[0xB5aeA0EAa7E0dEf3C2C8A52AB69676fD4F798aC0]=true;
    whitelisted[0x6F1b7a2E6bA6d93B09261B08D8E96954446eeb4c]=true;
    whitelisted[0x7656354162ac373A52783896E0DC9D1A1352d94d]=true;
    whitelisted[0x70DDc368a5EaD66E36DdE48A861eF416c6e9C7D4]=true;
    whitelisted[0x7B179130db6866b5c7641eDfb3aCf4B8505B9e6E]=true;
    whitelisted[0x895e5a6450489799fC6bd3270Fd948009A3F522C]=true;
    whitelisted[0xB2f20A8e528d2F3272E6A81aBF0f33e8d1D2d67F]=true;

  }
}