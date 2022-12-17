// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBalancerSwapVault {
  struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
  }

  struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address recipient;
    bool toInternalBalance;
  }

  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct PoolBalanceOp {
    uint8 kind;
    bytes32 poolId;
    address token;
    uint256 amount;
  }

  struct UserBalanceOp {
    uint8 kind;
    address asset;
    uint256 amount;
    address sender;
    address recipient;
  }

  struct SingleSwap {
    bytes32 poolId;
    uint8 kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
  }
}