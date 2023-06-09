// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract gemdevil is Ownable, ERC721A, ReentrancyGuard {
    uint256 public tokenCount;
    uint256 public mintPrice = 0.03 ether;
    uint256 private mintLimit = 100;
    uint256 public wlMintLimit = 3;
    uint256 public _totalSupply = 6666;
    uint256 public currentSupply= 66;
    bool public wlSaleStart = false;
    bool public openSaleStart = false;
    mapping(address => uint256) public Minted; 
    mapping(address => bool) public _whiteLists; 
    string private _baseTokenURI;

  constructor(
  ) ERC721A("gemdevil", "GD", mintLimit, _totalSupply) {
     tokenCount = 0;
  }
  function partnerMint(uint256 quantity, address to) external onlyOwner {
    require(
        (quantity + tokenCount) <= (_totalSupply), 
        "too many already minted before patner mint"
    );
    require(
        (quantity + tokenCount) <= (currentSupply), 
        "too many already minted before patner mint"
    );
    _safeMint(to, quantity);
    tokenCount += quantity;
  }
  function wlMint(uint256 quantity) public payable nonReentrant {
    require(wlMintLimit >= quantity, "limit over");
    require(wlMintLimit >= Minted[msg.sender] + quantity, "You have no Mint left");
    require(msg.value == mintPrice * quantity, "Value sent is not correct");
    require((quantity + tokenCount) <= (currentSupply), "Sorry. No more NFTs");
    require(wlSaleStart, "Sale Paused");
    require(_whiteLists[msg.sender] , "Your adress is not on the Whitelist.");
         
    Minted[msg.sender] += quantity;
    _safeMint(msg.sender, quantity);
    tokenCount += quantity;
  }
  function openSaleMint(uint256 quantity) public payable nonReentrant {
    require(mintLimit >= quantity, "limit over");
    require(msg.value == mintPrice * quantity, "Value sent is not correct");
    require((quantity + tokenCount) <= (currentSupply), "Sorry. No more NFTs");
    require(openSaleStart, "Sale Paused");
         
    _safeMint(msg.sender, quantity);
    tokenCount += quantity;
  }
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  function walletOfOwner(address _address) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_address);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
      for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_address, i);
      }
    return tokenIds;
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), "URI query for nonexistent token");
    return string(abi.encodePacked(_baseURI(), Strings.toString(_tokenId), ".json"));
  }

  function setBaseURI(string calldata baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function setWlMintLimit(uint256 newLimit) external onlyOwner {
    wlMintLimit = newLimit;
  }
  function setCurrentSupply(uint256 newSupply) external onlyOwner {
    require(_totalSupply >= newSupply, "totalSupplyover");
    currentSupply = newSupply;
  }
  function setMintPrice(uint256 newPrice) external onlyOwner {
    mintPrice = newPrice ;
  }
  function pushMultiWL(address[] memory list, bool _state) public virtual onlyOwner{
    for (uint i = 0; i < list.length; i++) {
      _whiteLists[list[i]]= _state;
    }
  }
  function setOwnersExplicit(uint256 quantity) external onlyOwner nonReentrant {
    _setOwnersExplicit(quantity);
  }
  function switchSaleStart(bool _state) external onlyOwner {
      wlSaleStart = _state;
  }
  function switchOpenSaleStart(bool _state) external onlyOwner {
      openSaleStart = _state;
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
}