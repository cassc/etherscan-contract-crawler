// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./interfaces/IMetaStreetApesNFT.sol";

contract MetaStreetApesPresale is
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable
{
  struct Config {
    uint256 startTime;
    uint256 endTime;
    uint256 supply;
    uint256 price;
    uint256 maxNFTAllowed;
  }

  Config public privateConfig;
  Config public publicConfig;
  mapping(address => uint256) public userPrivateCount;
  mapping(address => uint256) public userPublicCount;

  uint256 public privateCount;
  uint256 public publicCount;

  IMetaStreetApesNFT public nft;

  event SetSaleConfig(uint256 _startTime, uint256 _endTime, uint256 _supply, uint256 _price);
  event WithdrawETH(address indexed _sender, uint256 _balance);
  event Buy(address indexed _sender, uint256 _numberOfNft);

  /**
   * @dev Upgradable initializer
   */
  function __MetaStreetApesPresale_init(IMetaStreetApesNFT _nft) external initializer {
    __Ownable_init();
    __ReentrancyGuard_init();
    nft = _nft;
  }

  /**
   * @notice Set parameters for private sale
   * @dev Only callable by owner
   * @param _startTime Start time of sale
   * @param _endTime End time of sale
   * @param _supply Total Supply
   * @param _price Price of round
   * @param _maxNFTAllowed Max allowed NFT by user
   */
  function setPrivateSaleConfig(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _supply,
    uint256 _price,
    uint256 _maxNFTAllowed
  ) external onlyOwner {
    privateConfig = Config(_startTime, _endTime, _supply, _price, _maxNFTAllowed);
    emit SetSaleConfig(_startTime, _endTime, _supply, _price);
  }

  /**
   * @notice Set parameters for public sale
   * @dev Only callable by owner
   * @param _startTime Start time of sale
   * @param _endTime End time of sale
   * @param _supply Total Supply
   * @param _price Price of round
   * @param _maxNFTAllowed Max allowed NFT by user
   */
  function setPublicSaleConfig(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _supply,
    uint256 _price,
    uint256 _maxNFTAllowed
  ) external onlyOwner {
    publicConfig = Config(_startTime, _endTime, _supply, _price, _maxNFTAllowed);

    emit SetSaleConfig(_startTime, _endTime, _supply, _price);
  }

  /**
   * @notice Withdraw all Eth
   * @dev Only callable by owner
   */
  function withdrawETH() external onlyOwner {
    address payable sender_ = payable(_msgSender());

    uint256 balance_ = address(this).balance;
    sender_.transfer(balance_);

    emit WithdrawETH(sender_, balance_);
  }

  /**
   * @notice buy NFT in Private round
   * @dev Anyone can call this function
   * @param _numberOfNft Total number nft to buy
   * @dev Error Details
   * - 0x1: User in black list
   * - 0x2: There is no public sale running
   * - 0x3: Invalid price
   * - 0x4: User can't be muy more than max nft allowed
   * - 0x5: User can't buy more than public supply
   */
  function buyPrivate(uint256 _numberOfNft) external payable nonReentrant {
    address sender_ = _msgSender();
    require(block.timestamp > privateConfig.startTime && block.timestamp < privateConfig.endTime, "0x2");
    require(msg.value >= privateConfig.price * _numberOfNft, "0x3");
    require(userPrivateCount[sender_] + _numberOfNft <= privateConfig.maxNFTAllowed, "0x4");
    require(privateCount + _numberOfNft <= privateConfig.supply, "0x5");

    nft.bulkMint(_numberOfNft, sender_);
    userPrivateCount[sender_] = userPrivateCount[sender_] + _numberOfNft;
    privateCount = privateCount + _numberOfNft;

    emit Buy(sender_, _numberOfNft);
  }

  /**
   * @notice buy NFT in Private round
   * @dev Anyone can call this function
   * @param _numberOfNft Total number nft to buy
   * @dev Error Details
   * - 0x1: User in black list
   * - 0x2: There is no public sale running
   * - 0x3: Invalid price
   * - 0x4: User can't be muy more than max nft allowed
   * - 0x5: User can't buy more than public supply
   */
  function buyPublic(uint256 _numberOfNft) external payable nonReentrant {
    address sender_ = _msgSender();
    require(block.timestamp > publicConfig.startTime && block.timestamp < publicConfig.endTime, "0x2");
    require(msg.value >= publicConfig.price * _numberOfNft, "0x3");
    require(userPublicCount[sender_] + _numberOfNft <= publicConfig.maxNFTAllowed, "0x4");
    require(publicCount + _numberOfNft <= publicConfig.supply, "0x5");

    nft.bulkMint(_numberOfNft, sender_);
    userPublicCount[sender_] = userPublicCount[sender_] + _numberOfNft;
    publicCount = publicCount + _numberOfNft;

    emit Buy(sender_, _numberOfNft);
  }

}