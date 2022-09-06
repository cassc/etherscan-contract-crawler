// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

enum SwapKind { GIVEN_IN, GIVEN_OUT }

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    address assetIn;
    address assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address recipient;
    bool toInternalBalance;
}

enum PoolSpecialization { GENERAL, MINIMAL_SWAP_INFO, TWO_TOKEN }

interface IBalancerV2Vault {
    function batchSwap(SwapKind kind, BatchSwapStep[] calldata swaps, address[] calldata assets, FundManagement calldata funds, int256[] calldata limits, uint256 deadline) external returns (int256[] memory assetDeltas);
    function queryBatchSwap(SwapKind kind, BatchSwapStep[] calldata swaps, address[] calldata assets, FundManagement calldata funds) external returns (int256[] memory assetDeltas);
    function swap(SingleSwap calldata singleSwap, FundManagement calldata funds, uint256 limit, uint256 deadline) external returns (uint256 amountCalculatedInOut);
    function getPool(bytes32 poolId) external view returns (address, PoolSpecialization);
    function getPoolTokens(bytes32 poolId) external view returns (address[] memory tokens, uint256[] memory balances, uint256 lastChangeBlock);
}