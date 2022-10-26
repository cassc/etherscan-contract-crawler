// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/ICardPack.sol";

contract CardPackSell is Context, Ownable, Pausable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // Dont forget to set the selling parameter
  uint256 public constant MAX_SELL_PER_TX = 5;
  uint256 public constant MAX_SELL = 200;

  IERC20 public sellToken;
  ICardPack public pack;
  address public treasury;

  uint256 public totalSell;
  uint256 public startSellTimestamp;
  uint256 public packCategory;
  uint256 private price;

  mapping(address => uint256) public userSold;

  event SetPrice(uint256 price);
  event CardSale(address to, uint256 tokenId, uint256 category, uint256 price);

  constructor(
    ICardPack _pack,
    IERC20 _sellToken,
    uint256 _packCategory,
    uint256 _price,
    uint256 _startSellTimestamp,
    address _treasuryAddress
  ) {
    pack = _pack;
    sellToken = _sellToken;
    packCategory = _packCategory;
    price = _price;
    startSellTimestamp = _startSellTimestamp;
    treasury = _treasuryAddress;
  }

  modifier onlyEOA() {
    require(tx.origin == _msgSender(), "CardPackSell: onlyEOA");
    _;
  }

  function getPrice() public view returns (uint256) {
    return price;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;

    emit SetPrice(_price);
  }

  function buyCardPack(uint256 n) external onlyEOA whenNotPaused {
    require(
      block.timestamp >= startSellTimestamp,
      "CardPackSell: Sell has not started"
    );
    require(n <= MAX_SELL_PER_TX, "CardPackSell: Reach tx limit");

    totalSell += n;
    userSold[_msgSender()] += n;

    require(totalSell <= MAX_SELL, "CardPackSell: Reach user limit");

    sellToken.safeTransferFrom(_msgSender(), treasury, getPrice() * n);

    uint256 startTokenId = pack.currentTokenId() + 1;
    for (
      uint256 tokenId = startTokenId;
      tokenId < startTokenId + n;
      tokenId++
    ) {
      pack.mint(_msgSender(), packCategory);
      emit CardSale(_msgSender(), tokenId, packCategory, getPrice());
    }
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}