// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "hardhat/console.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract TwelveAnonymousTournaments is ERC721AQueryable, Ownable, ReentrancyGuard {
  uint256 public constant collectionSize = 5555;
  uint256 public constant prizeTokens = 555;
  uint256 public constant reservedTokens = 500;

  string public constant CLASS_L = "L";
  string public constant CLASS_E = "E";
  string public constant CLASS_R = "R";

  string public constant TYPE_AGILITY = "AGR";
  string public constant TYPE_STRENGTH = "STR";
  string public constant TYPE_PHYSICAL = "PHY";
  string public constant TYPE_INTELLIGENCE = "INT";
  string public constant TYPE_TECHNIQUE = "TEQ";

  uint256 public numberMintedForPrize = 0;

  struct SaleConfig {
    uint32 preSaleStartTime;
    uint32 publicSaleStartTime;
    uint32 endTime;
    uint32 maxPerAddress;
  }

  SaleConfig public saleConfig;
  
  mapping(address => uint256) public allowlist;
  mapping(address => uint256) public numberClaimed;
  
  bool public revealed = false;

  constructor() ERC721A("TWELVE ANONYMOUS TOURNAMENTS", "TAT") {
  }

 function mintToken(uint256 quantity) external payable {
    require(isPublicSale(), "mint has not begun yet");
    require(isSaleEnd()==false, "mint has ended");
    require(isSoldOut(quantity) == false, "reached max supply");
    require(numberClaimed[msg.sender] + quantity <= saleConfig.maxPerAddress, "exceeds mint limit");
    
    numberClaimed[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function allowlistMint(uint256 quantity) external payable {
    require(isPrivateSale(), "mint has not begun yet");
    require(isSaleEnd()==false, "mint has ended");
    require(isSoldOut(quantity) == false, "reached max supply");
    require(numberClaimed[msg.sender] + quantity <= allowlist[msg.sender], "not eligible for allowlist mint");

    numberClaimed[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
  }

  function prizeMint() external payable onlyOwner nonReentrant {
    require(numberMintedForPrize == 0, "already reserved for prize");
    numberMintedForPrize = prizeTokens;
    _safeMint(msg.sender, prizeTokens);
  } 

  function reserveMint() external payable onlyOwner nonReentrant {
    require(isSaleEnd(), "still on sale");
    uint256 quantity =  collectionSize - totalSupply();
    _safeMint(msg.sender, quantity);
  }
  
  function isPrivateSale() public view returns (bool) {
    uint256 startTime = uint256(saleConfig.preSaleStartTime);
    return startTime != 0 && block.timestamp >= startTime;
  }

  function isPublicSale() public view returns(bool) {
    uint256 startTime = uint256(saleConfig.publicSaleStartTime);
    return startTime != 0 && block.timestamp >= startTime;
  }
  
  function isSaleEnd() public view returns(bool) {
    uint256 endTime = uint256(saleConfig.endTime);
    return endTime != 0 && block.timestamp >= endTime;
  }

  function isSoldOut(uint256 quantity) public view returns(bool) {
    return (totalSupply() + quantity) > (collectionSize - reservedTokens);
  }

  function setSaleConfig(
    uint32 preSaleStartTime, 
    uint32 publicSaleStartTime, 
    uint32 endTime, 
    uint32 maxPerAddress
  ) external onlyOwner {
    saleConfig = SaleConfig(
      preSaleStartTime,
      publicSaleStartTime,
      endTime,
      maxPerAddress
    );
  }
    
  function reveal() public onlyOwner {
    revealed = true;
  }
  
  function seedAllowlist(address[] memory addresses, uint256[] memory numSlots) external onlyOwner {
    require(addresses.length == numSlots.length, "addresses does not match numSlots length");
    for (uint256 i = 0; i < addresses.length; i++) {
      allowlist[addresses[i]] = numSlots[i];
    }
  }

  mapping(uint256 => string) public customURI;  
  function seedCustomURI(uint256[] memory tokens, string[] memory uriList) external onlyOwner {
    require(tokens.length == uriList.length, "addresses does not match className length");
    for (uint256 i = 0; i < tokens.length; i++) {
      customURI[tokens[i]] = uriList[i];
    }
  }

  mapping(uint256 => uint256) public battlePoints;
  function seedBattlePoints(uint256[] memory tokens, uint256[] memory pointList) external onlyOwner {
    require(tokens.length == pointList.length, "tokens does not match pointList length");
    for (uint256 i = 0; i < tokens.length; i++) {
      battlePoints[tokens[i]] = pointList[i];
    }
  }

  mapping(uint256 => string) public classOfToken;
  function seedClass(uint256[] memory tokens, string[] memory classList) external onlyOwner {
    require(tokens.length == classList.length, "tokens does not match classList length");
    for (uint256 i = 0; i < tokens.length; i++) {
      classOfToken[tokens[i]] = classList[i];
    }
  }

  mapping(uint256 => string) public typeOfToken;
  function seedType(uint256[] memory tokens, string[] memory typeList) external onlyOwner {
    require(tokens.length == typeList.length, "tokens does not match typeList length");
    for (uint256 i = 0; i < tokens.length; i++) {
      typeOfToken[tokens[i]] = typeList[i];
    }
  }

  mapping(uint256 => string) public attributesOfToken;
  function seedAttributes(uint256[] memory tokens, string[] memory attributesList) external onlyOwner {
    require(tokens.length == attributesList.length, "tokens does not match attributesList length");
    for (uint256 i = 0; i < tokens.length; i++) {
      attributesOfToken[tokens[i]] = attributesList[i];
    }
  }

  // metadata URI
  string private _baseTokenURI;
  string private _placeholderTokenURI;
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }

  function setPlaceholderUri(string memory placeholderTokenUri) external onlyOwner{
    _placeholderTokenURI = placeholderTokenUri;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if(!_exists(tokenId)) revert URIQueryForNonexistentToken();
    if(revealed == false) {
        return _placeholderTokenURI;
    }
    
    string memory _tokenURI;
    if(keccak256(abi.encodePacked(classOfToken[tokenId])) == keccak256(abi.encodePacked(CLASS_L))) {
      _tokenURI = customURI[tokenId];
      return bytes(_tokenURI).length > 0 ?  _tokenURI : _placeholderTokenURI;
    }
    _tokenURI = super.tokenURI(tokenId);
    return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : _placeholderTokenURI;
  }

  function withdraw() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }

  function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
    return _ownershipOf(tokenId);
  }

}