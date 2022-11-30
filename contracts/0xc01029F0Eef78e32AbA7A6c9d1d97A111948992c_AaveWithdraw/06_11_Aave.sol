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