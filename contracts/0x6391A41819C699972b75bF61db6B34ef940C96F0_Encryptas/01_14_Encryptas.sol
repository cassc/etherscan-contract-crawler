// SPDX-License-Identifier: None
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Encryptas is Ownable, ERC721Enumerable {
  using SafeMath for uint256;

  uint256 public constant preSaleMintPrice = 0.045 ether;
  uint256 public constant mintPrice = 0.055 ether;
  uint256 public constant mintLimit = 20;

  uint256 public presaleLimit = 2000;
  uint256 public supplyLimit = 10000;

  string public baseURI;

  bool public isSaleActive = false;
  bool public isPresale = true;

  mapping(address => bool) private _presaleWhitelist;

  address private creator1Address = 0xF23296337d45DA62e34ceDbc80db478bda3cAF9b;
  address private creator2Address = 0x19461698453e26b98ceE5B984e1a86e13C0f68Be;
  address private devAddress = 0xe05AdCB63a66E6e590961133694A382936C85d9d;

  constructor(
    string memory inputBaseUri
  ) ERC721("Encryptas", "ENCRYPTAS") { 
    baseURI = inputBaseUri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function setBaseURI(string calldata newBaseUri) external onlyOwner {
    baseURI = newBaseUri;
  }
  
  function toggleSaleState() public onlyOwner {
    isSaleActive = !isSaleActive;
  }
  
  function setPresale(bool presaleActive) public onlyOwner {
    isPresale = presaleActive;
  }

  modifier onlyPresaleWhitelist {
    require(_presaleWhitelist[msg.sender], "Not on presale whitelist");
    _;
  }

  function addToWhitelist(address[] memory wallets) public onlyOwner {
    for(uint i = 0; i < wallets.length; i++) {
      _presaleWhitelist[wallets[i]] = true;
    }
  }

  function isOnWhitelist(address wallet) public view returns (bool) {
    return _presaleWhitelist[wallet];
  }

  function buyPresale(uint numberOfTokens) external onlyPresaleWhitelist payable {
    require(isSaleActive && isPresale, "Presale is not active");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");
    require(totalSupply().add(numberOfTokens) <= presaleLimit, "Not enough pre-sale tokens left");
    require(msg.value >= preSaleMintPrice.mul(numberOfTokens), "Insufficient payment");

    _mint(numberOfTokens);
  }

  function buy(uint numberOfTokens) external payable {
    require(isSaleActive && !isPresale, "Sale is not active");
    require(numberOfTokens <= mintLimit, "Too many tokens for one transaction");
    require(msg.value >= mintPrice.mul(numberOfTokens), "Insufficient payment");

    _mint(numberOfTokens);
  }

  function _mint(uint numberOfTokens) private {
    require(totalSupply().add(numberOfTokens) <= supplyLimit, "Not enough tokens left");

    uint256 newId = totalSupply();
    for(uint i = 0; i < numberOfTokens; i++) {
      newId += 1;
      _safeMint(msg.sender, newId);
    }
  }

  function reserve(uint256 numberOfTokens) external onlyOwner {
    _mint(numberOfTokens);
  }

  function withdraw() external onlyOwner {
    require(address(this).balance > 0, "No balance to withdraw");
    
    uint devShare = address(this).balance.mul(5).div(100);
    uint creatorShare = address(this).balance.mul(475).div(1000);

    (bool success, ) = devAddress.call{value: devShare}("");
    require(success, "Withdrawal failed");

    (success, ) = creator1Address.call{value: creatorShare}("");
    require(success, "Withdrawal failed");

    (success, ) = creator2Address.call{value: address(this).balance}("");
    require(success, "Withdrawal failed");
  }

  function tokensOwnedBy(address wallet) external view returns(uint256[] memory) {
    uint tokenCount = balanceOf(wallet);

    uint256[] memory ownedTokenIds = new uint256[](tokenCount);
    for(uint i = 0; i < tokenCount; i++){
      ownedTokenIds[i] = tokenOfOwnerByIndex(wallet, i);
    }

    return ownedTokenIds;
  }
}