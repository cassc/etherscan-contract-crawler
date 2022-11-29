// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/ISellableNFT.sol";

contract TokenSale is Ownable, ReentrancyGuard {
  using SafeERC20 for IERC20;

  event Sale(
    address user,
    address token,
    uint256 tokenId,
    address currency,
    uint256 price
  );

  event PriceChanged(
    address currency,
    uint256 price
  );

  event PauseStatusChanged(
    bool isPaused
  );

  /// @dev The token we will sell
  ISellableNFT public saleToken;

  /// @dev token address => price (0 = not valid buy token)
  mapping(address => uint256) public prices;

  /// @dev don't allow buys if paused
  bool public paused;

  modifier whenNotPaused() {
    require(!paused, "Token sale is paused");
    _;
  }

  constructor(
    ISellableNFT _saleToken
  )
  Ownable()
  ReentrancyGuard()
  {
    saleToken = _saleToken;
  }

  // PUBLIC SALE API

  function buy(
    address currency
  )
  external
  nonReentrant
  whenNotPaused
  {
    require(numAvailableToBuy() > 0, "No tokens available to buy");

    // Validate params
    uint256 price = prices[currency];
    require(price != 0, "Invalid buy currency");

    // Get money from user
    IERC20(currency).safeTransferFrom(msg.sender, address(this), price);

    // Send the token to the user
    uint256 tokenId = saleToken.safeMint(msg.sender);

    emit Sale(
      msg.sender,
      address(saleToken),
      tokenId,
      currency,
      price
    );
  }

  // PUBLIC VIEWS

  function numAvailableToBuy()
  public
  view
  returns (uint256) {
    return saleToken.MAX_SUPPLY() - saleToken.totalSupply();
  }

  // ADMIN FUNCTIONS

  function setPrice(
    address currency,
    uint256 price
  )
  external
  onlyOwner
  {
    prices[currency] = price;
    emit PriceChanged(
      currency,
      price
    );
  }

  function setPaused(
    bool newPaused
  )
  external
  onlyOwner
  {
    if (paused != newPaused) {
      paused = newPaused;
      emit PauseStatusChanged(
        newPaused
      );
    }
  }

  function withdrawEth(
    uint256 amount
  )
  external
  onlyOwner
  {
    (bool success,) = payable(owner()).call{ value: amount }("");
    require(success, "withdrawal failed");
  }

  function withdrawERC20(
    address token,
    uint256 amount
  )
  external
  onlyOwner
  {
    IERC20(token).safeTransfer(msg.sender, amount);
  }

  function withdrawERC721(
    address token,
    uint256 tokenId
  )
  external
  onlyOwner
  {
    IERC721(token).safeTransferFrom(address(this), msg.sender, tokenId);
  }
}