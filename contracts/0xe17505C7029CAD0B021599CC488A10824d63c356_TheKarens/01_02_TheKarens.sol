// SPDX-License-Identifier: UNLICENSED


/*.                                 THE KARENS

################################################################################
################################################################################
################################################################################
################################################################################
################################################################################
#############################...........%####..........#########################
##########################...  ........ .....  ......  .%#######################
###############,#(##(........................................((#((,,############
###############.%######.....................................######..############
##########################..............................%#######################
##########################..............................%#######################
#######################&&&,,,,,,,,,,,,,......,,,,,,,,,,,@&######################
##########&&&&&&&&&&&&&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&&&&&&&&&&###########
##&@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&#
##&@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&#
####&&&&&&&&&&&&&&&@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&&&&&&&&&&&&&&&###
####################&,,,,,,,,,,,,,@@@,,,,,,,,@@@,,,,,,,,,,,,&###################
####################&,,,,,,,,,,,,,,,,&&,,,,,&,,,,,,,,,,,,,,,&###################
####################&,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&###################
##################&@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&#################
##################&@,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,&&#################
##################&@,,,,,,,,,,,,,,,,,,,,@&,,,,,,,,,,,,,,,,,,,&&#################
##################&&&,,,,,,,,,,,,,,,,,,,@&,,,,,,,,,,,,,,,,,,&&&#################
##################&@,&&/,,,,,,,,,,,,,,,/@&//,,,,,,,,,,,,//&&/&&#################
####################&,,,@&&&&&&&&&&&&&&#####&&&&&&&&&&&&,,,,&###################
####################&,,,,,,,,,,,,,,,&########&&,,,,,,,,,,,,,&###################
#####################&&,,,,,,,,,,,,,&########&&,,,,,,,,,,,&&####################
#####################&&,,,,,,,,,,,&&#########&&,,,,,,,,,,,&&####################
#####################&&,,,,,,,,,,,&&#########&&,,,,,,,,,,,&&####################
#####################&&,,,,,,,,,,,&&#########&&,,,,,,,,,,,&&####################
#####################&&,,,,,,,,,,,,,&########&&,,,,,,,,,,,,,&###################
########################@&&&&&&&&&&&############@&&&&&&&&&&&####################
https://www.thekarens.io/
https://www.fyf.com/
https://twitter.com/fyfdotcom


*/


//Smart Contract by TheSheep#1211
pragma solidity ^0.8.0;
import "./ERC721S.sol";

contract TheKarens is ERC721A, Ownable {
  using Strings for uint256;

  string private uriPrefix = "https://thekarens.sfo3.digitaloceanspaces.com/json/";
  string private uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public price = 0.01 ether; // 0.01 eth Whitelisted addresses price 0.02 eth Public mint price (20000000000000000 wei)
  uint256 public maxSupply = 2000; 
  uint256 public maxMintAmountPerTx = 10; 
  uint256 public nftPerAddressLimitWl = 2; 
  
  bool public paused = false;
  bool public revealed = true;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  mapping(address => uint256) public addressMintedBalance;


  constructor() ERC721A("TheKarens", "KRN$", maxMintAmountPerTx) {
    setHiddenMetadataUri("");
  }

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(currentIndex + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount)
   {
    require(!paused, "The contract is paused!");
    require(!onlyWhitelisted, "Presale is on");
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
    
    
    _safeMint(msg.sender, _mintAmount);
  }

   function mintWhitelist(uint256 _mintAmount) public payable {
    uint256 ownerMintedCount = addressMintedBalance[msg.sender];
    
    require(!paused, "The contract is paused!");
    require(onlyWhitelisted, "Presale has ended");
    require(ownerMintedCount + _mintAmount <= nftPerAddressLimitWl, "max NFT per address exceeded");
    if(onlyWhitelisted == true) {
            require(isWhitelisted(msg.sender), "address is not Whitelisted");
        }
    require(msg.value >= price * _mintAmount, "Insufficient funds!");
    
    addressMintedBalance[msg.sender]+=_mintAmount;
    
    _safeMint(msg.sender, _mintAmount);
  }



  
  function AirdropTo(address _to, uint256 _mintAmount) public mintCompliance(_mintAmount) onlyOwner {
    _safeMint(_to, _mintAmount);
  }

 
  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 0;
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
      return hiddenMetadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }


  function setOnlyWhitelisted(bool _state) public onlyOwner {
    onlyWhitelisted = _state;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;

  }
 
  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setNftPerAddressLimitWl(uint256 _limit) public onlyOwner {
    nftPerAddressLimitWl = _limit;
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

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
      _safeMint(_receiver, _mintAmount);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
    
  }

    function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;

  }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
    maxSupply = _maxSupply;

    
  }
  function addWhitelistUsers(address[] calldata _users) public onlyOwner { //ARRAY users
    whitelistedAddresses = _users;
  }

    function isWhitelisted(address _user) public view returns (bool) {
    for (uint i = 0; i < whitelistedAddresses.length; i++) {
      if (whitelistedAddresses[i] == _user) {
          return true;
      }
    }
    return false;
  }

  // withdrawall addresses
  address t1 = 0xDeD17018BDD1302d389b06a5280cEb6F7F1b146F;
  

  function withdrawall() public onlyOwner {
        uint256 _balance = address(this).balance;
        
        require(payable(t1).send(_balance * 100 / 100 ));

  }
   function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
    
 
  }
  
}