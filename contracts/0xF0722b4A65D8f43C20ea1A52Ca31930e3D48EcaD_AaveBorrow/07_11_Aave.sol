pragma solidity ^0.8.15;

struct DepositData {
  address asset;
  uint256 amount;
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