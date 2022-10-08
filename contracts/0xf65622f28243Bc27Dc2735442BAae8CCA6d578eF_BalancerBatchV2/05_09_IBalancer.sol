// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct BatchSwapStep {
    bytes32 poolId;
    uint256 assetInIndex;
    uint256 assetOutIndex;
    uint256 amount;
    bytes userData;
}

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

struct SingleSwap {
    bytes32 poolId;
    SwapKind kind;
    IAsset assetIn;
    IAsset assetOut;
    uint256 amount;
    bytes userData;
}

struct FundManagement {
    address sender;
    bool fromInternalBalance;
    address payable recipient;
    bool toInternalBalance;
}

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

interface IBalancer {
    function batchSwap(
        uint8 kind,
        BatchSwapStep[] memory swaps,
        IAsset[] memory assets,
        FundManagement memory funds,
        int256[] memory limits,
        uint256 deadline
    ) external returns (int256[] memory assetDeltas);

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}