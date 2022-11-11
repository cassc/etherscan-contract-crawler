pragma solidity ^0.8.15;

struct FlashloanData {
  uint256 amount;
  bool dsProxyFlashloan;
  Call[] calls;
}

struct PullTokenData {
  address asset;
  address from;
  uint256 amount;
}

struct SendTokenData {
  address asset;
  address to;
  uint256 amount;
}

struct SetApprovalData {
  address asset;
  address delegate;
  uint256 amount;
}

struct SwapData {
  address fromAsset;
  address toAsset;
  uint256 amount;
  uint256 receiveAtLeast;
  uint256 fee;
  bytes withData;
  bool collectFeeInFromToken;
}

struct Call {
  bytes32 targetHash;
  bytes callData;
}

struct Operation {
  uint8 currentAction;
  bytes32[] actions;
}

struct WrapEthData {
  uint256 amount;
}

struct UnwrapEthData {
  uint256 amount;
}

struct ReturnFundsData {
  address asset;
}