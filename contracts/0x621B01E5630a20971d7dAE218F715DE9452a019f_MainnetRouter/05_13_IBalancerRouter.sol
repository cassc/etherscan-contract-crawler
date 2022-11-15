// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IBalancerRouter {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
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
        address payable recipient;
        bool toInternalBalance;
    }

    struct Asset {
        string symbol;
        uint8 decimals;
        uint256 limit;
    }

    struct BatchSwapStep {
        bytes32 poolId;
        uint256 assetInIndex;
        uint256 assetOutIndex;
        uint256 amount;
        bytes userData;
    }

    function swap(
        SingleSwap memory swap,
        FundManagement memory fund,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] calldata swaps,
        address[] calldata assets,
        FundManagement memory fund,
        int256[] calldata limits,
        uint256 deadline
    ) external payable returns (int256[] calldata assetDeltas);
}