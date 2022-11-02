// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/ITreasuryBootstrap.sol";

import "./WhitelistSalePublic.sol";

/// @title TreasuryBootstrap
/// @author Bluejay Core Team
/// @notice TreasuryBootstrap is a token sale contract that supports public token sale as well as
/// whitelisted sale at different prices. Purchased BLU tokens are sent immediately to the buyer.
contract TreasuryBootstrap is ITreasuryBootstrap, WhitelistSalePublic {
  using SafeERC20 for IERC20;

  /// @notice Public price of the token against the reserve asset, in WAD
  uint256 public publicPrice;

  /// @notice Constructor to initialize the contract
  /// @param _reserve Address the asset used to purchase the BLU token
  /// @param _treasury Address of the treasury
  /// @param _price Price of the token for whitelisted sale, in WAD
  /// @param _maxPurchasable Maximum number of BLU tokens that can be purchased, in WAD
  /// @param _merkleRoot Merkle root of the distribution
  /// @param _publicPrice Price of the token for public sale, in WAD
  constructor(
    address _reserve,
    address _treasury,
    uint256 _price,
    uint256 _maxPurchasable,
    bytes32 _merkleRoot,
    uint256 _publicPrice
  )
    WhitelistSalePublic(
      _reserve,
      _treasury,
      _price,
      _maxPurchasable,
      _merkleRoot
    )
  {
    publicPrice = _publicPrice;
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Public purchase of tokens from the sale
  /// @param amount Amount of reserve assset to use for purchase
  /// @param recipient Address where BLU will be sent to
  function publicPurchase(uint256 amount, address recipient) public override {
    require(!paused, "Purchase paused");
    uint256 tokensBought = (amount * WAD) / publicPrice;

    totalPurchased += tokensBought;
    require(totalPurchased <= maxPurchasable, "Max purchasable reached");

    reserve.safeTransferFrom(msg.sender, address(treasury), amount);
    treasury.mint(recipient, tokensBought);

    emit PublicPurchase(msg.sender, recipient, amount, tokensBought);
  }
}