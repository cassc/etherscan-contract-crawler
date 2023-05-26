//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "./PathHelper.sol";

/**
 Path Dao
 */
contract Path is ERC721Enumerable, ERC721URIStorage, VRFConsumerBase, Ownable, PathHelper {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  bool public saleStarted = false;
  bool public whitelistedSale = false;
  
  struct PathToken {
      uint8 template;
      uint8 pathCount;
      uint8 windTurbulence;
      uint32 pathSeed;
      uint32 windSeed;
  }

  uint256 public constant MAX_SUPPLY = 5000;
  uint256 public price = 0.08 ether;
  uint256 public transformPrice = 0.01 ether;
  uint256 public randomNumber = 115792089237316195423570985008687907853269984665640564039457584007913129639935; // default random

  uint16 public MAX_MINT = 10;
  uint16 public MAX_WHITELIST_MINT = 2;

  string public baseURI;
  mapping(address => bool) whitelistedAddress;
  mapping(address => uint256) public whitelistMinted;
  mapping(uint256 => PathToken) public tokenIdAttr;
  mapping(uint256 => string) public tokenIdSentence;
  mapping(uint256 => uint256) public remainingTransforms;
  mapping(uint256 => uint256) public transformNumber;

  event PathBuilt(uint256 indexed tokenId, PathToken path, address indexed owner);
  event Transformed(uint256 indexed tokenId, PathToken path, string sentence, address indexed owner);
  event RequestedRandomNumber(bytes32 indexed requestId);
  event FulfilledRandomNumber(bytes32 indexed requestId, uint256 randomNumber);


  constructor() 
  VRFConsumerBase(
    0xf0d54349aDdcf704F77AE15b96510dEA15cb7952,
    0x514910771AF9Ca656af840dff83E8264EcF986CA)
  ERC721("Path", "PATH") {}

  function addtoWhitelist(address[] calldata addresses) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      require(addresses[i] != address(0), "Can't add a null address");
      whitelistedAddress[addresses[i]] = true;
      whitelistMinted[addresses[i]] > 0 ? whitelistMinted[addresses[i]] : 0;
    }
  }

  function whitelistMintPath(uint256 quantity) public payable {
    require(whitelistedSale, "Sale has not started yet.");
    require(whitelistedAddress[msg.sender], "User is not whitelisted");
    require(quantity > 0, "Mint number cannot be zero");
    require(quantity <= MAX_WHITELIST_MINT, "Mint number exceeds maximum per transaction");
    require(whitelistMinted[msg.sender] + quantity <= MAX_WHITELIST_MINT, "Max mint for presale");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity requested exceeds max supply.");
    require(msg.value >= price * quantity, "Ether value sent is below the price");


    for (uint256 i = 0; i < quantity; i++) {
      // get tokenId
      uint256 mintIndex = _tokenIds.current();
      
      // mint
      _safeMint(msg.sender, mintIndex);

      //add 1 burn to count
      remainingTransforms[mintIndex] = 1;

      // init attributes for path
      uint256 pathAttr = uint256(keccak256(abi.encode(randomNumber, mintIndex + block.number, block.timestamp, msg.sender))) % (10 ** 32);
      string memory pathAttrStr = uint2str(pathAttr);
      uint8 pathCount = generatePaths(pathAttrStr);
      uint8 windTurbulence = generateWind(pathAttrStr);
      uint8 template = checkTemplate(pathAttrStr);
      uint32 pathSeed = getPathSeed(pathAttrStr);
      uint32 windSeed = getWindSeed(pathAttrStr);
      
      tokenIdAttr[mintIndex] = PathToken(template, pathCount, windTurbulence, pathSeed, windSeed);

      // increment id counter
      _tokenIds.increment();
      //increment mint_count
      whitelistMinted[msg.sender]++;
    
      emit PathBuilt(mintIndex, tokenIdAttr[mintIndex], msg.sender);
    }
  }

  function mintPath(uint256 quantity) public payable {
    require(saleStarted, "Sale has not started yet.");
    require(quantity > 0, "Mint number cannot be zero");
    require(quantity <= MAX_MINT, "Mint number exceeds maximum per transaction");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity requested exceeds max supply.");
    require(msg.value >= price * quantity, "Ether value sent is below the price");

    // (bool success, ) = payoutAccountAddress.call{value: msg.value}("");
    // require(success, "Address: unable to send value, recipient may have reverted");

    for (uint256 i = 0; i < quantity; i++) {
      // initialize tokenId
      uint256 mintIndex = _tokenIds.current();
      
      // mint
      _safeMint(msg.sender, mintIndex);

      //add 1 burn to count
      remainingTransforms[mintIndex] = 1;

      // init attributes for path
      uint256 pathAttr = uint256(keccak256(abi.encode(randomNumber, mintIndex + block.number, block.timestamp, msg.sender))) % (10 ** 32);
      string memory pathAttrStr = uint2str(pathAttr);
      uint8 pathCount = generatePaths(pathAttrStr);
      uint8 windTurbulence = generateWind(pathAttrStr);
      uint8 template = checkTemplate(pathAttrStr);
      uint32 pathSeed = getPathSeed(pathAttrStr);
      uint32 windSeed = getWindSeed(pathAttrStr);
      
      tokenIdAttr[mintIndex] = PathToken(template, pathCount, windTurbulence, pathSeed, windSeed);
    
      // increment id counter
      _tokenIds.increment();
      emit PathBuilt(mintIndex, tokenIdAttr[mintIndex], msg.sender);
    }
  }
  
  //reserve mints for giveaways
  function reserveMint(uint quantity) external onlyOwner {
    require(quantity > 0, "Mint number cannot be zero");
    require(totalSupply() + quantity <= MAX_SUPPLY, "Quantity requested exceeds max supply.");


    for (uint256 i = 0; i < quantity; i++) {
      // initialize tokenId
      uint256 mintIndex = _tokenIds.current();
      
      // mint
      _safeMint(msg.sender, mintIndex);

      //add 1 burn to count
      remainingTransforms[mintIndex] = 1;

      uint256 pathAttr = uint256(keccak256(abi.encode(randomNumber, mintIndex + block.number, block.timestamp, msg.sender))) % (10 ** 32);
      string memory pathAttrStr = uint2str(pathAttr);
      uint8 pathCount = generatePaths(pathAttrStr);
      uint8 windTurbulence = generateWind(pathAttrStr);
      uint8 template = checkTemplate(pathAttrStr);
      uint32 pathSeed = getPathSeed(pathAttrStr);
      uint32 windSeed = getWindSeed(pathAttrStr);
      
      tokenIdAttr[mintIndex] = PathToken(template, pathCount, windTurbulence, pathSeed, windSeed);
      // increment id counter
      _tokenIds.increment();
      emit PathBuilt(mintIndex, tokenIdAttr[mintIndex], msg.sender);
    }   
  }

  function transformFreePath(uint256 _tokenId, string memory sentence) public{
    require(ownerOf(_tokenId) == msg.sender, "Caller does not own this token");
    require(remainingTransforms[_tokenId] > 0, "No more remaining burns");

    remainingTransforms[_tokenId]--;
    tokenIdSentence[_tokenId] = sentence;
    transformNumber[_tokenId]++;
    emit Transformed(_tokenId, tokenIdAttr[_tokenId], sentence, msg.sender);
  }

  function transformPath(uint256 _tokenId, string memory sentence) public payable{
    require(ownerOf(_tokenId) == msg.sender, "Caller does not own this token");
    require(msg.value >= transformPrice, "Ether value sent is below the price");

    tokenIdSentence[_tokenId] = sentence;
    transformNumber[_tokenId]++;

    emit Transformed(_tokenId, tokenIdAttr[_tokenId], sentence, msg.sender);
  }

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function setSaleStarted() public onlyOwner {
    saleStarted = !saleStarted;
  }

  function setWhitelistSale() public onlyOwner {
    whitelistedSale = !whitelistedSale;
  }

  function hasSaleStarted() public view returns (bool) {
    return saleStarted;
  }

  function setPrice(uint256 _price) public onlyOwner {
    price = _price;
  }

  function setTransformPrice(uint256 _transformPrice) public onlyOwner {
    transformPrice = _transformPrice;
  }

  function hasSoldOut() public view returns (bool) {
    if (totalSupply() >= MAX_SUPPLY) {
      return true;
    } else {
      return false;
    }
  }

  function requestRandomNumber(bytes32 keyhash, uint256 fee) public onlyOwner returns (bytes32) {
    bytes32 requestId = requestRandomness(keyhash, fee);
    emit RequestedRandomNumber(requestId);
    return requestId;
  }

  function fulfillRandomness(bytes32 requestId, uint256 _randomNumber) internal override {
    randomNumber = _randomNumber;
    emit FulfilledRandomNumber(requestId, _randomNumber);
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function totalSupply() public view override returns (uint256) {
    return _tokenIds.current();
  }

  //override functions
  function tokenURI(uint256 tokenId)public view override(ERC721, ERC721URIStorage)
    returns (string memory) {
      return super.tokenURI(tokenId);
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal
    override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
    super._burn(tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable)
    returns (bool) {
      return super.supportsInterface(interfaceId);
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
  }
}