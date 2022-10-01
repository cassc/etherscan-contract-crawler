// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract NFTContractSHOT is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string notRevealedUri;

  uint256 public cost = 0.075 ether;
  uint256 public allowListCost = 0.06 ether;
  uint256 public totalReveal = 0;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmount = 20;

  bool public saleIsActive = false;
  bool public revealed = false;
  bool public isAllowListActive = false;

  mapping(address => uint8) private _allowList;
  mapping(address => uint8) private _allowFreeList;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    uint256 _cost,
    uint256 _allowListCost,
    uint256 _maxSupply,
    uint256 _maxMintAmount
  ) ERC721(_name, _symbol) {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    setCost(_cost);
    setAllowListCost(_allowListCost);
    setMaxSupply(_maxSupply);
    setMaxMintAmount(_maxMintAmount);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  /**
   * Set some aside
   */
  function reserve(uint256 n) public onlyOwner {
    uint256 supply = totalSupply();
    uint256 i;
    for (i = 0; i < n; i++) {
      _safeMint(msg.sender, supply + i);
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  /**
   * Mints
   */
  function mint(uint256 numberOfTokens) public payable {
    require(saleIsActive, "Sale must be active to mint tokens");
    require(
      numberOfTokens <= maxMintAmount,
      "Purchase would exceed max supply per wallet"
    );
    require(
      totalSupply() + numberOfTokens <= maxSupply,
      "Purchase would exceed max tokens"
    );
    require(
      cost * numberOfTokens <= msg.value,
      "Ether value sent is not correct"
    );

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = totalSupply();
      if (totalSupply() < maxSupply) {
        _safeMint(msg.sender, mintIndex);
      }
    }
  }

  function withdraw() public onlyOwner {
    uint256 balance = address(this).balance;
    payable(msg.sender).transfer(balance);
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
    require(_exists(tokenId), "URI query for nonexistent token");

    if (totalReveal == 0 || tokenId >= totalReveal) {
      return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return
      bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), ".json"))
        : "";
  }

  function mintAllowList(uint8 numberOfTokens) external payable {
    uint256 ts = totalSupply();

    require(isAllowListActive, "Allow list is not active");
    require(
      numberOfTokens <= _allowList[msg.sender],
      "Exceeded max available to purchase"
    );
    require(
      ts + numberOfTokens <= maxSupply,
      "Purchase would exceed max tokens"
    );
    require(
      allowListCost * numberOfTokens <= msg.value,
      "Ether value sent is not correct"
    );

    _allowList[msg.sender] -= numberOfTokens;
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, ts + i);
    }
  }

  function mintFree(uint8 numberOfTokens) external payable {
    uint256 ts = totalSupply();

    require(saleIsActive, "Sale must be active to mint tokens");
    require(
      numberOfTokens <= _allowFreeList[msg.sender],
      "Exceeded max available to purchase or not allowed"
    );
    require(
      ts + numberOfTokens <= maxSupply,
      "Purchase would exceed max tokens"
    );

    _allowFreeList[msg.sender] -= numberOfTokens;
    for (uint256 i = 0; i < numberOfTokens; i++) {
      _safeMint(msg.sender, ts + i);
    }
  }

  function setIsAllowListActive(bool _isAllowListActive) external onlyOwner {
    isAllowListActive = _isAllowListActive;
  }

  function setAllowList(address[] calldata addresses, uint8 numAllowedToMint)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      _allowList[addresses[i]] = numAllowedToMint;
    }
  }

  function setFreeList(address[] calldata addresses, uint8 numAllowedToMint)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < addresses.length; i++) {
      _allowFreeList[addresses[i]] = numAllowedToMint;
    }
  }

  function numAvailableToMint(address addr) external view returns (uint8) {
    return _allowList[addr];
  }

  function numFreeAvailableToMint(address addr) external view returns (uint8) {
    return _allowFreeList[addr];
  }

  //only owner
  function reveal() public onlyOwner {
    revealed = true;
  }

  function setAllowListCost(uint256 _allowListCost) public onlyOwner {
    allowListCost = _allowListCost;
  }

  function getAllowListCost() external view returns (uint256) {
    return allowListCost;
  }

  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function getCost() external view returns (uint256) {
    return cost;
  }

  function setMaxSupply(uint256 _maxMintAmount) public onlyOwner {
    maxSupply = _maxMintAmount;
  }

  function getMaxSupply() external view returns (uint256) {
    return maxSupply;
  }

  function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  }

  function setTotalReveal(uint256 _totalReveal) public onlyOwner {
    totalReveal = _totalReveal;
  }

  function getTotalReveal() external view returns (uint256) {
    return totalReveal;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setSaleState(bool newState) public onlyOwner {
    saleIsActive = newState;
  }
}