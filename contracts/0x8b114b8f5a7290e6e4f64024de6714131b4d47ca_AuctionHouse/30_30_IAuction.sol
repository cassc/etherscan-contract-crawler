// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./ICases.sol";

interface IAuction is ICases {
  /**
   * The current Stabilisation Case
   * Auction's target price.
   * Auction's floatInEth price.
   * Auction's bankInEth price.
   * Auction's basket factor.
   * Auction's used float delta.
   * Auction's allowed float delta (how much FLOAT can be created or burned).
   */
  struct Auction {
    Cases stabilisationCase;
    uint256 targetFloatInEth;
    uint256 marketFloatInEth;
    uint256 bankInEth;
    uint256 startWethPrice;
    uint256 startBankPrice;
    uint256 endWethPrice;
    uint256 endBankPrice;
    uint256 basketFactor;
    uint256 delta;
    uint256 allowance;
  }
}