//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract FlowtyInkArt is ERC1155Supply, Ownable, ReentrancyGuard {
  using Strings for uint256;

  bool public saleActive = false;
  uint256 public totalTokens = 0;
  uint256 public currentMintTokenId;
  uint256 public currentMintTokenPrice;
  IERC20 public INKToken;

  // Number of mints per each tokenId
  mapping(uint256 => uint256) private _supply;
  // Starting block # for each tokenId
  mapping(uint256 => uint256) private _ages;
  // metadata URI
  mapping(uint256 => string) private tokenBaseURI;

  // Period of "aging" for each tokenId expressed in blocks, e.g tokenId 1 ages within 3 days 
  // The threshold between metadata changes, when we need to show a different image
  struct AgeParams { 
    uint256 period;
    uint256 threshold;
  }
  mapping(uint256 => AgeParams) private _ageParams;

  constructor(IERC20 INKTokenAddress) ERC1155("FLOWTY INK ART") {
    INKToken = INKTokenAddress;
  }

  function flipSaleActive() external onlyOwner {
    saleActive = !saleActive;
  }

  modifier saleIsActive() {
    require(saleActive, "The sale is not active");
    _;
  }

  function setBaseURI(uint256 tokenId, string calldata baseURI) external onlyOwner {
    tokenBaseURI[tokenId] = baseURI;
  }

  function setCurrentMintTokenId(uint256 tokenId, uint256 price) external onlyOwner {
    currentMintTokenId = tokenId;
    currentMintTokenPrice = price;
  }

  // Set the period and a threshold for a certain TokenType
  function setAging(uint256 tokenId, uint256 period, uint256 threshold) external onlyOwner {
    _ageParams[tokenId].period = period;
    _ageParams[tokenId].threshold = threshold;
    _ages[tokenId] = block.number;
  }

  function mintArt(uint256 tokenId, uint256 qty)
    external
    nonReentrant
    saleIsActive
  {
    require(tokenId == currentMintTokenId, "Trying to mint non active token");
    uint price = currentMintTokenPrice * qty;
    uint256 buyerINKBalance = INKToken.balanceOf(msg.sender);
    require(price <= buyerINKBalance, "Insufficient funds: Not enough $INK for sale price");
    
    INKToken.transferFrom(msg.sender, address(this), price);

    _mint(msg.sender, tokenId, qty, "");
    _supply[tokenId] += qty;
  }

  function mintArtTo(address mintAddress, uint256 tokenId, uint256 qty)
    external
    nonReentrant
    onlyOwner
  {
    _mint(mintAddress, tokenId, qty, "");
    _ages[tokenId] = block.number;
    _supply[tokenId] += qty;
  }

  function withdraw() public onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawAllINK() public onlyOwner {
    uint256 balance = INKToken.balanceOf(address(this));
    require(balance > 0, "No $INK within this contract");
    INKToken.transfer(msg.sender, balance);
  }

  // Just in case anyone sends us any random ERC20
  function withdrawErc20(address erc20Contract, uint256 _amount) public onlyOwner {
    uint256 erc20Balance = IERC20(erc20Contract).balanceOf(address(this));
    require(erc20Balance >= _amount, "Insufficient funds: not enough ERC20");
    IERC20(erc20Contract).transfer(msg.sender, _amount);
  }

  function getSupply(uint256 tokenId)
    public
    view 
    returns (uint256)
  {
    return _supply[tokenId];
  }

  // Returns the age stage for a given tokenId based on starting point and current block #
  // Result is a sequential number depending on _ageBlocksThreshold
  // Starts from 0 and corresponds to the very first image & metadata
  function getAge(uint256 tokenId) 
    public 
    view
    tokenExists(tokenId)
    returns (uint256)
  {
    if (_ages[tokenId] > 0) {
      uint256 currentAge = (uint((block.number - _ages[tokenId]) % _ageParams[tokenId].period) / _ageParams[tokenId].threshold);
      return currentAge;
    }
    return 0;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }

  modifier tokenExists(uint256 id) {
    require(getSupply(id) > 0, "Token does not exist");
    _;
  }

  //---------------------------------------------------------------------------------
  // We build URL is a following way: tokenBaseURI[tokenId] + AGE (0...period)
  function tokenURI(uint256 tokenId) tokenExists(tokenId) public view returns (string memory) {
    string memory _baseTokenURI = tokenBaseURI[tokenId];
    return bytes(_baseTokenURI).length > 0 ? 
          string(
            abi.encodePacked(abi.encodePacked(_baseTokenURI, getAge(tokenId).toString()))) : "";  }
}