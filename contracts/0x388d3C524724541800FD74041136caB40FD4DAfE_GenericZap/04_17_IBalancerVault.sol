pragma solidity ^0.8.4;
// SPDX-License-Identifier: AGPL-3.0-or-later


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBalancerVault {
  struct JoinPoolRequest {
    IERC20[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IERC20 assetIn;
    IERC20 assetOut;
    uint256 amount;
    bytes userData;
  }

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
    address payable recipient;
    bool toInternalBalance;
  }

  enum SwapKind { GIVEN_IN, GIVEN_OUT }

  function swap(
      SingleSwap memory singleSwap,
      FundManagement memory funds,
      uint256 limit,
      uint256 deadline
  ) external payable returns (uint256 amountCalculated);

  function joinPool(
      bytes32 poolId,
      address sender,
      address recipient,
      JoinPoolRequest memory request
  ) external payable;

  function getPoolTokens(
    bytes32 poolId
  ) external view
    returns (
      address[] memory tokens,
      uint256[] memory balances,
      uint256 lastChangeBlock
  );

  function queryBatchSwap(
    SwapKind kind,
    BatchSwapStep[] memory swaps,
    IERC20[] memory assets,
    FundManagement memory funds
  ) external view returns (int256[] memory);
}