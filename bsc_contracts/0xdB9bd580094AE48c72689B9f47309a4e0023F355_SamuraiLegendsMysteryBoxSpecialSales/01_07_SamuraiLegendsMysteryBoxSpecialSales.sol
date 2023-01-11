// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./Recoverable.sol";

interface ISamuraiLegendsMysteryBoxes {
  function totalSupply() external view returns (uint256);

  function mint(address user) external;
}

enum PriceType {
  BNB,
  ERC20
}

/**
 * @title Contract that adds samurai mystery boxes selling functionalities.
 * @author Leo
 */
contract SamuraiLegendsMysteryBoxSpecialSales is Ownable, Recoverable, ReentrancyGuard, Pausable {
  ISamuraiLegendsMysteryBoxes public immutable factory;

  IERC20 public token;

  uint160 public mysteryBoxPrice;
  uint40 public mintLimit;
  bool public discountEnabled;

  string public name;

  PriceType public priceType;

  constructor(
    string memory _name,
    IERC20 _token,
    ISamuraiLegendsMysteryBoxes _factory,
    PriceType _priceType,
    uint160 _mysteryBoxPrice,
    uint40 _mintLimit
  ) {
    name = _name;
    token = _token;
    factory = _factory;
    priceType = _priceType;
    mysteryBoxPrice = _mysteryBoxPrice;
    mintLimit = _mintLimit;

    _pause();
  }

  /**
   * @notice Computes the available mysteryBoxes.
   */
  function availableMysteryBoxes() public view returns (uint256) {
    return mintLimit - factory.totalSupply();
  }

  /**
   * @notice Lets a user buy a new mysteryBox.
   * @param _numberOfMysteryBoxes Number of mystery boxes.
   */
  function buyMysteryBox(uint256 _numberOfMysteryBoxes) external payable nonReentrant whenNotPaused {
    require(_numberOfMysteryBoxes > 0, "invalid mysteryBoxes number");
    require(availableMysteryBoxes() > 0, "mint limit reached");

    uint256 numberOfMysteryBoxes = min(_numberOfMysteryBoxes, availableMysteryBoxes());

    if (priceType == PriceType.BNB) {
      require(msg.value == mysteryBoxPrice * numberOfMysteryBoxes, "invalid bnb amount");
    } else if (priceType == PriceType.ERC20) {
      require(msg.value == 0, "you can't buy with bnb");
    }

    for (uint256 i = 0; i < numberOfMysteryBoxes; i++) {
      factory.mint(msg.sender);
    }

    if (priceType == PriceType.ERC20) {
      token.transferFrom(msg.sender, address(this), mysteryBoxPrice * numberOfMysteryBoxes);
    }

    _applyDiscount(numberOfMysteryBoxes);

    emit MysteryBoxesBought(msg.sender);
  }

  /**
   * @notice Apply discount.
   * @param _numberOfMysteryBoxes Number of mystery boxes.
   */
  function _applyDiscount(uint256 _numberOfMysteryBoxes) private {
    if (discountEnabled) {
      for (uint256 i = 0; i < _numberOfMysteryBoxes / 2; i++) {
        factory.mint(msg.sender);
      }

      emit DiscountApplied(msg.sender);
    }
  }

  /**
   * @notice Updates mysteryBox price.
   * @param _priceType New price type.
   * @param _mysteryBoxPrice New mysteryBoxPrice.
   */
  function updateMysteryBoxPrice(PriceType _priceType, uint112 _mysteryBoxPrice) external onlyOwner {
    priceType = _priceType;
    mysteryBoxPrice = _mysteryBoxPrice;

    emit PriceUpdated(_mysteryBoxPrice);
  }

  /**
   * @notice Updates mysteryBox sells limit.
   * @param _mintLimit New mysteryBox sells limit.
   */
  function updateMintLimit(uint40 _mintLimit) external onlyOwner {
    require(_mintLimit >= factory.totalSupply(), "invalid mint limit");

    mintLimit = _mintLimit;

    emit MintLimitUpdated(_mintLimit);
  }

  /**
   * @notice Updates ERC20 token address.
   * @param _token New ERC20 address.
   */
  function updateToken(IERC20 _token) external onlyOwner {
    token = _token;

    emit TokenUpdated(address(_token));
  }

  /**
   * @notice Enable/Disable discount.
   * @param value New discount enabled value.
   */
  function updateDiscountEnabled(bool value) external onlyOwner {
    discountEnabled = value;

    emit DiscountEnabledUpdated(value);
  }

  /**
   * @dev Returns the smallest of two numbers.
   */
  function min(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  /**
   * @notice Lets the owner pause the contract.
   */
  function pause() external whenNotPaused onlyOwner {
    _pause();
  }

  /**
   * @notice Lets the owner unpause the contract.
   */
  function unpause() external whenPaused onlyOwner {
    _unpause();
  }

  event PriceUpdated(uint160 _mysteryBoxPrice);
  event MintLimitUpdated(uint48 _dailyLimit);
  event TokenUpdated(address _token);
  event MysteryBoxesBought(address indexed user);
  event DiscountApplied(address indexed user);
  event DiscountEnabledUpdated(bool value);
}