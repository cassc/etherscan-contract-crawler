// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../interfaces/IMooEgg.sol";

contract ByBitEggSell is Context, Ownable, Pausable {
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // Dont forget to set the selling parameter
  uint256 public constant MAX_SELL_PER_TX = 3;
  uint256 public constant MAX_SELL = 3000;
  uint256 public constant MAX_SELL_PER_USER = 3000;

  IERC20 public sellToken;
  IMooEgg public mooEgg;
  address public treasury;

  uint256 public totalSell;
  uint256 public totalPackSell;
  uint256 public startSellTimestamp;
  uint256 public price;

  mapping(address => uint256) public userSold;

  event SetPrice(uint256 price);
  event EggSale(address to, uint256 tokenId, uint256 totalEggSell);
  event PackSale(address to, uint256 totalPackSell);

  constructor(
    IMooEgg _mooEgg,
    IERC20 _sellToken,
    uint256 _price,
    uint256 _startSellTimestamp,
    address _treasuryAddress
  ) {
    mooEgg = _mooEgg;
    sellToken = _sellToken;
    price = _price;
    startSellTimestamp = _startSellTimestamp;
    treasury = _treasuryAddress;
  }

  modifier onlyEOA() {
    require(tx.origin == _msgSender(), "EggSell: onlyEOA");
    _;
  }

  function getPrice() public view returns (uint256) {
    return price;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;

    emit SetPrice(_price);
  }

  function buyEggs() external onlyEOA whenNotPaused {
    uint256 n = 3;

    require(
      block.timestamp >= startSellTimestamp,
      "EggSell: Sell has not started"
    );
    require(n <= MAX_SELL_PER_TX, "EggSell: Reach tx limit");

    totalSell += n;
    userSold[_msgSender()] += n;
    totalPackSell += 1;

    require(totalSell <= MAX_SELL, "EggSell: Reach user limit");
    require(
      userSold[_msgSender()] <= MAX_SELL_PER_USER,
      "EggSell: Reach user limit"
    );

    sellToken.safeTransferFrom(_msgSender(), treasury, getPrice() * n);

    uint256 startTokenId = mooEgg.currentTokenId() + 1;
    for (
      uint256 tokenId = startTokenId;
      tokenId < startTokenId + n;
      tokenId++
    ) {
      mooEgg.mint(msg.sender, IMooEgg.EggCategory.NONE);
      emit EggSale(_msgSender(), tokenId, price);
    }
    emit PackSale(_msgSender(), totalPackSell);
  }

  function pause() external onlyOwner {
    _pause();
  }

  function unpause() external onlyOwner {
    _unpause();
  }
}