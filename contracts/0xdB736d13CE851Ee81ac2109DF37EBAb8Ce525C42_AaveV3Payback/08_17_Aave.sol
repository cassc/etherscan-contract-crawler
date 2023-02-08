// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.15;

struct DepositData {
  address asset;
  uint256 amount;
  bool sumAmounts;
  bool setAsCollateral;
}

struct BorrowData {
  address asset;
  uint256 amount;
  address to;
}

struct WithdrawData {
  address asset;
  uint256 amount;
  address to;
}

struct PaybackData {
  address asset;
  uint256 amount;
  bool paybackAll;
}

/**
 * CategoryId indicates special categories voted in by AAVE governance
 * that give special LTVs and thresholds to specific categories/groupings of [email protected]
 * The first of these was ETH correlated assets with an ID of 1.
 */
struct SetEModeData {
  uint8 categoryId;
}