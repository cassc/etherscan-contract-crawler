//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./ClaimableERC721Tradable.sol";

contract OverHypedPandas is ClaimableERC721Tradable, ReentrancyGuard {
  using Counters for Counters.Counter;

  uint256 private launchTimestamp;
  uint256 private publicSaleTimestamp;

  uint256 private maxMintsWalletAddress = 10;
  
  uint256 private totalPandasCount = 5000;
  uint256 private tokenTiersCount = 4; // Excluding Giveaways tier
  uint256 private whiteListedCount = 0; // Excluding Giveaways tier
  uint256 private totalSalesCount = 0;

  bool paused = false;

  mapping(address => bool) private whiteListed;
  mapping(address => uint256) private userMints;

  mapping(uint256 => uint256) private tierPrices;
  mapping(uint256 => uint256) private tierSales;
  mapping(uint256 => uint256) private tierAmounts;
  mapping(uint256 => uint256) private tokenTiers;

  constructor(
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress,
    uint256 _launchTimestamp,
    uint256 _publicSaleTimestamp)
    ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
    tierPrices[0] = 950000000000000000; // 0.95 ETH
    tierPrices[1] = 750000000000000000; // 0.75 ETH
    tierPrices[2] = 500000000000000000; // 0.50 ETH
    tierPrices[3] = 250000000000000000; // 0.25 ETH

    tierAmounts[0] = 750;  
    tierAmounts[1] = 1000; 
    tierAmounts[2] = 1250; 
    tierAmounts[3] = 1750; 
    tierAmounts[4] = 250; // Giveaways

    launchTimestamp = _launchTimestamp;
    publicSaleTimestamp = _publicSaleTimestamp;
  }

  function mintPanda(uint256 _tier) public payable {
    require(_tier < tokenTiersCount, "Invalid tier");
    require(block.timestamp >= launchTimestamp && (block.timestamp >= publicSaleTimestamp || whiteListed[_msgSender()] == true), "Sale still not open");
    require(msg.value >= tierPrices[_tier], "Insufficient ETH");
    require(userMints[_msgSender()] + 1 <= maxMintsWalletAddress, "Minting exceeded");

    userMints[_msgSender()] += 1;

    _mintPanda(_tier, _msgSender());
  }

  function mintGiveaway(uint256 _tier, address _to) external onlyOwner {
    require(_tier <= tokenTiersCount, "Invalid tier");
    require(_to != address(0), "Invalid destination address");
    _mintPanda(_tier, _to);
  }

  function _mintPanda(uint256 _tier, address _to) private {
    require(!paused, "Minting is paused");
    require(totalSalesCount < totalPandasCount && tierSales[_tier] < tierAmounts[_tier], "Tier sold-out");

    uint256 tokenId = _nextTokenId.current();
    _nextTokenId.increment();
    _safeMint(_to, tokenId);

    tokenTiers[tokenId] = _tier;
    totalSalesCount += 1;
    tierSales[_tier] += 1;

    emit PandaMinted(_to, tokenId, _tier);
  }

  function addToWhitelist(address[] memory _addresses) external onlyOwner {
    require(_addresses.length > 0, "No addresses");
    for (uint256 i = 0; i < _addresses.length; i++) {
      whiteListed[_addresses[i]] = true;
      whiteListedCount += 1;
      emit AddedToWhiteList(_addresses[i]);
    }
  }

  function movePandasTier(uint256 _amount, uint256 _fromTier, uint256 _toTier) external onlyOwner {
    require(_fromTier <= tokenTiersCount && _toTier <= tokenTiersCount, "Invalid tier");
    require(tierAmounts[_fromTier] - tierSales[_fromTier] >= _amount, "Not enough pandas to move");

    tierAmounts[_fromTier] -= _amount;
    tierAmounts[_toTier] += _amount;

    emit PandasMoved(_amount, _fromTier, _toTier);
  }

  function removeFromWhitelist(address _address) external onlyOwner {
    require(whiteListed[_address] == true, "Not whitelisted");
    whiteListed[_address] = false;
    whiteListedCount--;
    emit RemovedFromWhiteList(_address);
  }

  function setPaused(bool _paused) external onlyOwner {
    paused = _paused;
  }

  function burn(uint256 _tokenId) external {
    _burn(_tokenId);
  }

  function baseTokenURI() override public pure returns (string memory) {
    return "https://nft-meta.overhyped.io/pandas/series1/";
  }

  function getAvailableByTier(uint256 _tier) public view returns(uint256 amount) {
    return tierAmounts[_tier] - tierSales[_tier];
  }

  function getTierOf(uint256 _tokenId) public view returns(uint256 tier) {
    return tokenTiers[_tokenId];
  }

  function getTotalSales() public view onlyOwner returns(uint256 total) {
    return totalSalesCount;
  }

  function getWhitelistedSaleOpen() public view returns(bool open) {
    return block.timestamp >= launchTimestamp;
  }

  function getPublicSaleOpen() public view returns(bool open) {
    return block.timestamp >= publicSaleTimestamp;
  }

  /** Events **/
  event PandaMinted(address indexed minter, uint256 indexed tokenId, uint256 indexed tier);
  event PandasMoved(uint256 indexed amount, uint256 indexed fromTier, uint256 indexed toTier);
  event AddedToWhiteList(address indexed whitelistAddress);
  event RemovedFromWhiteList(address indexed removedAddress);

}