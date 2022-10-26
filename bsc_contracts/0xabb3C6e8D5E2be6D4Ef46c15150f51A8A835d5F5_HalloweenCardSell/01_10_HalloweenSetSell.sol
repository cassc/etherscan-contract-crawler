// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IMooCard.sol";
import "../interfaces/ICardPack.sol";

contract HalloweenCardSell is Context, Ownable, Pausable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // Dont forget to set the selling parameter
  uint256 public constant MAX_SELL_PER_TX = 5;
  uint256 public constant MAX_SELL = 200;
  uint256 public constant MAX_SELL_PER_USER = 50;

  IERC20 public sellToken;
  IMooCard public mooCard;
  ICardPack public pack;
  address public treasury;

  uint256 public totalSell;
  uint256 public startSellTimestamp;
  uint256 public cardCategory;
  uint256 public packCategory1;
  uint256 public packCategory2;
  uint256 private price;

  mapping(address => uint256) public userSold;

  event SetPrice(uint256 price);
  event CardSale(
    address to,
    uint256 tokenId,
    uint256 category,
    uint256 packCategory1,
    uint256 packCategory2,
    uint256 price
  );

  constructor(
    IMooCard _mooCard,
    ICardPack _pack,
    IERC20 _sellToken,
    uint256 _cardCategory,
    uint256 _packCategory1,
    uint256 _packCategory2,
    uint256 _price,
    uint256 _startSellTimestamp,
    address _treasuryAddress
  ) {
    mooCard = _mooCard;
    pack = _pack;
    sellToken = _sellToken;
    cardCategory = _cardCategory;
    packCategory1 = _packCategory1;
    packCategory2 = _packCategory2;
    price = _price;
    startSellTimestamp = _startSellTimestamp;
    treasury = _treasuryAddress;
  }

  modifier onlyEOA() {
    require(tx.origin == _msgSender(), "CardSell: onlyEOA");
    _;
  }

  function getPrice() public view returns (uint256) {
    return price;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;

    emit SetPrice(_price);
  }

  function buyCard(uint256 n) external onlyEOA whenNotPaused {
    require(
      block.timestamp >= startSellTimestamp,
      "CardSell: Sell has not started"
    );
    require(n <= MAX_SELL_PER_TX, "CardSell: Reach tx limit");

    totalSell += n;
    userSold[_msgSender()] += n;

    require(totalSell <= MAX_SELL, "CardSell: Reach user limit");
    require(
      userSold[_msgSender()] <= MAX_SELL_PER_USER,
      "CardSell: Reach user limit"
    );

    sellToken.safeTransferFrom(_msgSender(), treasury, getPrice() * n);

    uint256 startTokenId = mooCard.currentTokenId() + 1;
    for (
      uint256 tokenId = startTokenId;
      tokenId < startTokenId + n;
      tokenId++
    ) {
      mooCard.mintCard(_msgSender(), cardCategory);
      pack.mint(_msgSender(), packCategory1);
      pack.mint(_msgSender(), packCategory2);
      emit CardSale(
        _msgSender(),
        tokenId,
        cardCategory,
        packCategory1,
        packCategory2,
        getPrice()
      );
    }
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}