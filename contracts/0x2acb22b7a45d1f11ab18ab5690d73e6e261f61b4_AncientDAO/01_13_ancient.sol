// Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';

contract AncientDAO is ERC721, ERC721Enumerable, Ownable {
  using Strings for uint256;
  bool public _isSaleActive = false;
  bool public _isAuctionActive = false;
  bool public isWhiteListActive = false;
  // Constants
  uint256 constant public MAX_SUPPLY = 10000;
  uint256 public mintPrice = 0 ether;
  uint256 public tierSupply = 1995;
  uint256 public tierWhitelist = 0;
  uint256 public maxBalance = 2;
  uint256 public maxMint = 2;
  // Auction variables
  uint256 public auctionStartTime;
  uint256 public auctionTimeStep;
  uint256 public auctionStartPrice;
  uint256 public auctionEndPrice;
  uint256 public auctionPriceStep;
  uint256 public auctionStepNumber;
  // Mapping for Whitelist
  mapping(address => uint256) private _allowList;
  // NFT URI
  string private _baseURIExtended = 'ipfs://QmbNJ2EFdQ1nQRy48xSJkbUwJtnwu8QUHKoTinbhRBn9xN/';

  event TokenMinted(uint256 supply);
  event SaleStarted();
  event SalePaused();
  event AuctionStarted();
  event AuctionPaused();
  // init
  constructor() ERC721('Ancient DAO', 'AnDAO') {}
  // Status of the Contract
  function startSale() external onlyOwner {
    require(! _isSaleActive, 'Sale is already began');
    _isSaleActive = true;
    emit SaleStarted();
  }
  function pauseSale() external onlyOwner {
    require(_isSaleActive, 'Sale is already paused');
    _isSaleActive = false;
    emit SalePaused();
  }
  function startAuction() external onlyOwner {
    require(!_isAuctionActive, 'Auction is already began');
    _isAuctionActive = true;
    emit AuctionStarted();
  }
  function pauseAuction() external onlyOwner {
    require(_isAuctionActive, 'Auction is already paused');
    _isAuctionActive = false;
    emit AuctionPaused();
  }
  function setIsWhiteListActive(bool _isAllowListActive) external onlyOwner {
    isWhiteListActive = _isAllowListActive;
  }

  // Variables for diff round
  function setMintPrice(uint256 _mintPrice) external onlyOwner {
    mintPrice = _mintPrice;
  }
  function setTierSupply(uint256 _tierSupply) external onlyOwner {
    tierSupply = _tierSupply;
  }
  function setWhitelistSupply(uint256 _whitelistSupply) external onlyOwner {
    tierWhitelist = _whitelistSupply;
  }
  function setMaxBalance(uint256 _maxBalance) external onlyOwner {
    maxBalance = _maxBalance;
  }
  function setMaxMint(uint256 _maxMint) external onlyOwner {
    maxMint = _maxMint;
  }
  function setWhiteList(address[] calldata addresses, uint256 numAllowedToMint) external onlyOwner {
    for (uint256 i = 0; i < addresses.length; i++) {
      _allowList[addresses[i]] = numAllowedToMint;
    }
  }
  function setAuction(uint256 _auctionStartTime, uint256 _auctionTimeStep, uint256 _auctionStartPrice, uint256 _auctionEndPrice, uint256 _auctionPriceStep, uint256 _auctionStepNumber) public onlyOwner {
    auctionStartTime = _auctionStartTime;
    auctionTimeStep = _auctionTimeStep;
    auctionStartPrice = _auctionStartPrice;
    auctionEndPrice = _auctionEndPrice;
    auctionPriceStep = _auctionPriceStep;
    auctionStepNumber = _auctionStepNumber;
  }

  function withdraw(address to) public onlyOwner {
    uint256 balance = address(this).balance;
    payable(to).transfer(balance);
  }

  function preserveMint(uint numtts, address to) public onlyOwner {
    require(totalSupply() + numtts <= tierSupply, 'Preserve mint would exceed tier supply');
    require(totalSupply() + numtts <= MAX_SUPPLY, 'Preserve mint would exceed max supply');
    _mintAnDAO(numtts, to);
    emit TokenMinted(totalSupply());
  }

  function getTotalSupply() public view returns (uint256) {
    return totalSupply();
  }

  function getAnDAOByOwner(address _owner) public view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }

  function getAuctionPrice() public view returns (uint256) {
    if (block.timestamp == auctionStartTime) {
      return auctionStartPrice;
    }
    if ((auctionStartTime + auctionTimeStep * auctionStepNumber) < block.timestamp) {
      return auctionEndPrice;
    }
    uint256 step = (block.timestamp - auctionStartTime) / auctionTimeStep; 
    uint256 auctionPrice = auctionStartPrice - step * auctionPriceStep;
    return auctionPrice;
  }

  function mintAnDAO(uint256 nums) external payable {
    uint256 ts = totalSupply();
    require(_isSaleActive, 'Sale must be active to mint Ancient DAO');
    require(ts + nums <= tierSupply, 'Sale would exceed tier supply');
    require(ts + nums <= MAX_SUPPLY, 'Sale would exceed max supply');
    require(balanceOf(msg.sender) + nums <= maxBalance, 'Sale would exceed max balance');
    require(nums <= maxMint, 'Sale would exceed max mint');
    require(nums * mintPrice <= msg.value, 'Not enough ether sent');
    _mintAnDAO(nums, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function mintWhiteList(uint256 nums) external payable {
    uint256 ts = totalSupply();
    require(isWhiteListActive, "White list is not active to mint Ancient DAO");
    require(nums <= _allowList[msg.sender], "Exceeded max available to purchase");
    require(ts + nums <= (tierWhitelist+tierSupply), 'Sale would exceed Whitelist supply');
    require(ts + nums <= MAX_SUPPLY, 'Sale would exceed max supply');
    require(balanceOf(msg.sender) + nums <= maxBalance, 'Sale would exceed max balance');
    require(nums <= maxMint, 'Sale would exceed max mint');
    _allowList[msg.sender] -= nums;
    _mintAnDAO(nums, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function auctionMintAnDAO(uint256 nums) external payable {
    uint256 ts = totalSupply();
    require(_isAuctionActive, 'Auction must be active to mint Ancient DAO');
    require(block.timestamp >= auctionStartTime, 'Auction not start');
    require(ts + nums <= tierSupply, 'Auction would exceed tier supply');
    require(ts + nums <= MAX_SUPPLY, 'Auction would exceed max supply');
    require(balanceOf(msg.sender) + nums <= maxBalance, 'Auction would exceed max balance');
    require(nums <= maxMint, 'Auction would exceed max mint');
    require(nums * getAuctionPrice() <= msg.value, 'Not enough ether sent');
    _mintAnDAO(nums, msg.sender);
    emit TokenMinted(totalSupply());
  }

  function _mintAnDAO(uint256 nums, address recipient) internal {
    uint256 supply = totalSupply();
    for (uint256 i = 0; i < nums; i++) {
      _safeMint(recipient, supply + i);
    }
  }

  function setBaseURI(string memory baseURI_) external onlyOwner {
    _baseURIExtended = baseURI_;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseURIExtended;
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');
    return string(abi.encodePacked(_baseURI(), tokenId.toString()));
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
    override(ERC721, ERC721Enumerable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}