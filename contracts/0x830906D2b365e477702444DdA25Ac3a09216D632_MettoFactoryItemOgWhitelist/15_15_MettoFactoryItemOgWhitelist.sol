// SPDX-License-Identifier: MIT
/// 
///
///
///███╗   ███╗███████╗████████╗████████╗ ██████╗                                      
///████╗ ████║██╔════╝╚══██╔══╝╚══██╔══╝██╔═══██╗                                     
///██╔████╔██║█████╗     ██║      ██║   ██║   ██║                                     
///██║╚██╔╝██║██╔══╝     ██║      ██║   ██║   ██║                                     
///██║ ╚═╝ ██║███████╗   ██║      ██║   ╚██████╔╝                                     
///╚═╝     ╚═╝╚══════╝   ╚═╝      ╚═╝    ╚═════╝                                      
///                                                                                                                                                                 
///                                                                                                                                                                                          
///
///                                                 
/// Metto item factory with OG and Whitelist mint options                                    
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol"; 
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";



contract MettoFactoryItemOgWhitelist is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public metadataUri;
  bool public isSingleMetadataUri = false;
  
  uint256 public ogListPrice;
  uint256 public whiteListPrice;
  uint256 public maxSupply = 0;
  uint256 public maxMintAmountPerOgTx = 1;
  uint256 public maxMintAmountPerWhitelistTx = 1;

  bool public whitelistMintEnabled = false;
  bool public ogMintEnabled = false;

  mapping(address => bool) whitelist;
  mapping(address => bool) oglist;

  mapping(address => bool) whitelistMinted;
  mapping(address => bool) ogListMinted;

  constructor(
    string memory _collectionName, 
    string memory _tokenSymbol, 
    string memory _metadataUri, 
    uint256 _ogListPrice, 
    uint256 _whiteListPrice, 
    uint256 _maxMintAmountPerOgTx,
    uint256 _maxMintAmountPerWhitelistTx,
    uint256 _maxSupply, 
    bool _isSingleMetadataUri
  ) ERC721(_collectionName, _tokenSymbol) {
    setOgListPrice(_ogListPrice);
    setWhiteListPrice(_whiteListPrice);
    setmaxMintAmountPerOgTx(_maxMintAmountPerOgTx);
    setmaxMintAmountPerWhitelistTx(_maxMintAmountPerWhitelistTx);
    setMetadataUri(_metadataUri);
    setMaxSupply(_maxSupply);
    setSingleMetadataUri(_isSingleMetadataUri);
  }


  function setWhiteListPrice(uint256 _price) public onlyOwner {
    whiteListPrice = _price;
  }


  function setOgListPrice(uint256 _price) public onlyOwner {
    ogListPrice = _price;
  }

  function setmaxMintAmountPerOgTx(uint256 _amount) public onlyOwner {
    maxMintAmountPerOgTx = _amount;
  }

  function setmaxMintAmountPerWhitelistTx(uint256 _amount) public onlyOwner {
    maxMintAmountPerWhitelistTx = _amount;
  }

  function setMetadataUri(string memory _metadataUri) public onlyOwner {
    bytes memory tempMetadataUri = bytes(metadataUri); 
    require(tempMetadataUri.length < 1, "Metadata URI has already been set");
    metadataUri = _metadataUri;
  }

  function setSingleMetadataUri(bool _isSingleMetadataUri) public onlyOwner {

    isSingleMetadataUri = _isSingleMetadataUri;   

  }

  function setMaxSupply(uint _maxSupply) public onlyOwner {

    require(maxSupply < 1, "Max supply has already been set");

    maxSupply = _maxSupply;   

  }

  modifier onlyWhitelisted() {
    require(isWhitelisted(msg.sender), "You are not whitelisted");
    _;
  }

  modifier hasNotWhitelistMinted() {
    require(!whitelistMinted[msg.sender], "You have already minted during whitelist mint.");
    _;
  }

  modifier hasNotOglistMinted() {
    require(!ogListMinted[msg.sender], "You have already minted during OG mint.");
    _;
  }

  function isWhitelisted(address _address) public view returns (bool) {
      return whitelist[_address];
  }

  function hasWhitelistMinted(address _address) public view returns (bool) {
      return whitelistMinted[_address];
  }

  function isOglisted(address _address) public view returns (bool) {
      return oglist[_address];
  }

  function hasOgListMinted(address _address) public view returns (bool) {
      return ogListMinted[_address];
  }

  // function hasPublicMinted(address _address) public view returns (bool) {
  //     return publicMinted[_address];
  // }

  function whitelistAdd(address _address) public onlyOwner {
      whitelist[_address] = true;
  }

  function whitelistAddMultiple(address[] memory users) public onlyOwner {
      for (uint i = 0; i < users.length; i++) {
          whitelist[users[i]] = true;
      }
  }
  function oglistAdd(address _address) public onlyOwner {
      oglist[_address] = true;
  }

  function oglistAddMultiple(address[] memory users) public onlyOwner {
      for (uint i = 0; i < users.length; i++) {
          oglist[users[i]] = true;
      }
  }

  function whitelistRemove(address _address) public onlyOwner {
      whitelist[_address] = false;
  }
  function oglistRemove(address _address) public onlyOwner {
      oglist[_address] = false;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable {

    require(whitelistMintEnabled || ogMintEnabled, "Minting not enabled!");

    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");

    if(ogMintEnabled && !isWhitelisted(msg.sender)) {
      require(isOglisted(msg.sender), "You are not in OG list!");
      require(!hasOgListMinted(msg.sender), "You have already minted during OG mint.");
      require(_mintAmount <= maxMintAmountPerOgTx, "Too much amount to mint.");
      require(msg.value >= ogListPrice * _mintAmount, "Insufficient funds!");
      _mintLoop(msg.sender, _mintAmount);
      ogListMinted[msg.sender] = true;
      return;
    } 

    if(whitelistMintEnabled) {
      require(isWhitelisted(msg.sender), "You are not whitelisted!");
      require(!hasWhitelistMinted(msg.sender), "You have already minted during whitelist mint.");
      require(_mintAmount <= maxMintAmountPerWhitelistTx, "Too much amount to mint.");
      require(msg.value >= whiteListPrice * _mintAmount, "Insufficient funds!");
      _mintLoop(msg.sender, _mintAmount);
      whitelistMinted[msg.sender] = true;
      return;
    }

  }

  function ogMint(uint256 _mintAmount) public payable {

    require(ogMintEnabled, "OG Minting not enabled!");

    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    require(isOglisted(msg.sender), "You are not in OG list!");
    require(!hasOgListMinted(msg.sender), "You have already minted during OG mint.");
    require(_mintAmount <= maxMintAmountPerOgTx, "Too much amount to mint.");
    require(msg.value >= ogListPrice * _mintAmount, "Insufficient funds!");
    _mintLoop(msg.sender, _mintAmount);
    ogListMinted[msg.sender] = true;

  }

  function wlMint(uint256 _mintAmount) public payable {

    require(whitelistMintEnabled, "Whitelist minting not enabled!");
    require(isWhitelisted(msg.sender), "You are not whitelisted!");
    require(!hasWhitelistMinted(msg.sender), "You have already minted during whitelist mint.");
    require(_mintAmount <= maxMintAmountPerWhitelistTx, "Too much amount to mint.");
    require(msg.value >= whiteListPrice * _mintAmount, "Insufficient funds!");
    _mintLoop(msg.sender, _mintAmount);
    whitelistMinted[msg.sender] = true;

  }
  

  function mintForAddress(uint256 _mintAmount, address _receiver) public onlyOwner {
    _mintLoop(_receiver, _mintAmount);
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

    if (isSingleMetadataUri) {
      return metadataUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setOgMintEnabled(bool _state) public onlyOwner {
    ogMintEnabled = _state;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
  }

  function setAllMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
    ogMintEnabled = _state;
  }

  function withdraw() public onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return metadataUri;
  }
}