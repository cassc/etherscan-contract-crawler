// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/security/ReentrancyGuard.sol";
import "openzeppelin-solidity/contracts/utils/Strings.sol";
import { IERC2981, IERC165 } from "openzeppelin-solidity/contracts/interfaces/IERC2981.sol";

contract ShibnobiNFT is ERC721, IERC2981, Ownable, ReentrancyGuard {
  using Strings for uint256;

  uint256 public constant MAX_SUPPLY = 10000;
  uint256 private _currentId;
  uint256 public maxPerWallet = 24;
  uint public startTime;

  string public baseURI;
  string private _contractURI;

  uint public bonus = 1;
  uint public bonusMin = 3;

  uint256 public basePrice = 0.05 ether;
  uint256 public increment = 0.015 ether;
  uint256 public discount  = 0.015 ether;
  mapping(address => uint256) private _alreadyMinted;
  mapping(uint256 => bool) public used1;
  mapping(uint256 => bool) public used2;
  address public royalties;
  ERC721 public GGG1;
  ERC721 public GGG2;



  constructor(
    address _royalties,
    string memory _initialBaseURI,
    string memory _initialContractURI,
    uint _startTime,
    ERC721 ggg1,
    ERC721 ggg2
  ) ERC721("Shibnobi Legacy Collection", "SLC") {
    royalties = _royalties;
    baseURI = _initialBaseURI;
    _contractURI = _initialContractURI;
    startTime = _startTime;
    GGG1 = ggg1;
    GGG2 = ggg2;
  }

  function setGGG(ERC721 _ggg1, ERC721 _ggg2) external onlyOwner {
    GGG1 = _ggg1;
    GGG2 = _ggg2;
  }

  function setBonus(uint n) external onlyOwner {
    bonus = n;
  }

  function setBonusMin(uint n) external onlyOwner {
    bonusMin = n;
  }

  function currentSupply() external view returns(uint) {
    return _currentId;
  }

  function setStartTime(uint t) external onlyOwner{
    startTime = t;
  }

  function setBasePrice(uint n) external onlyOwner {
      basePrice = n;
  }

  function setMaxPerWallet(uint n) external onlyOwner {
      maxPerWallet = n;
  }

  // Accessors

  function setRoyalties(address _royalties) public onlyOwner {
    royalties = _royalties;
  }


  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    string memory base = _baseURI();
    return bytes(base).length > 0 ? string(abi.encodePacked(base, tokenId.toString(), ".json")) : "";
  }

  function alreadyMinted(address addr) public view returns (uint256) {
    return _alreadyMinted[addr];
  }

  // Metadata

  function setBaseURI(string memory uri) public onlyOwner {
    baseURI = uri;
  }

  function _baseURI() internal view override returns (string memory) {
    return baseURI;
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  function setContractURI(string memory uri) public onlyOwner {
    _contractURI = uri;
  }

  // Minting

  function setDiscount(uint n) external onlyOwner {
    discount = n;
  }

  function getPrice(address a, uint amount) public view returns(uint) {
    uint _discount = 0;
    uint disCount = GGG1.balanceOf(a) + GGG2.balanceOf(a);
    uint remaining = 0;
    if (disCount > 0){
      disCount = disCount > _alreadyMinted[a] ? disCount - _alreadyMinted[a] : 0;
      if (disCount != 0){
        _discount = discount;
        if (disCount < amount) {
          remaining = amount - disCount;
        }
      }
    }
    
    if(_currentId <= 2500) {
      return ((basePrice - _discount) * amount) + remaining * _discount;
    } else if (_currentId > 2500 && _currentId <= 5000 ) {
      return ((basePrice + increment - _discount) * amount) + remaining * _discount;
    } else if(_currentId > 5000 && _currentId <= 7500) {
      return ((basePrice + 2 * increment - _discount) * amount) + remaining * _discount;
    } else {
      return ((basePrice + 3 * increment - _discount) * amount) + remaining * _discount;
    }
  }

  function mintPublic(
    uint256 amount
  ) public payable nonReentrant {
    address sender = _msgSender();
    require(block.timestamp >= startTime && startTime > 0);
    require(amount <= maxPerWallet - _alreadyMinted[sender], "Insufficient mints left");
    require(msg.value == getPrice(sender,amount), "Incorrect payable amount");
    
    _alreadyMinted[sender] += amount;
    uint b = amount / bonusMin * bonus;

    _internalMint(sender, amount + b);
  }

  function ownerMint(address to, uint256 amount) public onlyOwner {
    _internalMint(to, amount);
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function _internalMint(address to, uint256 amount) private {
    require(_currentId + amount <= MAX_SUPPLY, "Will exceed maximum supply");

    for (uint256 i = 1; i <= amount; i++) {
      _currentId++;
      _safeMint(to, _currentId);
    }
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address, uint256 royaltyAmount) {
    _tokenId;
    royaltyAmount = _salePrice * 5 / 100;
    return (royalties, royaltyAmount);
  }

  function setAM(address[] calldata a, uint[] calldata n) external onlyOwner {
    for(uint i;i<a.length;i++){
      _alreadyMinted[a[i]] += n[i];
    }
  }

  function ownerMint_(address[] calldata a, uint[] calldata n) external onlyOwner {
    for(uint i;i<a.length;i++){
      _currentId++;
      __mint(a[i], n[i]);
    }
  }
}