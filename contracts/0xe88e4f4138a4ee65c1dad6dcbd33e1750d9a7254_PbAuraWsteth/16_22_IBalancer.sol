// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IBalancer {
    enum SwapKind { GIVEN_IN, GIVEN_OUT }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        address assetIn;
        address assetOut;
        uint amount;
        bytes userData;
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address recipient;
        bool toInternalBalance;
    }

    function swap(
        SingleSwap memory singleSwap,
        FundManagement memory funds,
        uint limit,
        uint deadline
    ) external returns (uint amountCalculated);

    enum JoinKind { 
        INIT, 
        EXACT_TOKENS_IN_FOR_BPT_OUT, 
        TOKEN_IN_FOR_EXACT_BPT_OUT,
        ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
    }

    struct JoinPoolRequest {
        address[] assets;
        uint[] maxAmountsIn;
        bytes userData;
        bool fromInternalBalance;
    }

    function joinPool(
        bytes32 poolId,
        address sender,
        address recipient,
        JoinPoolRequest memory request
    ) external;

    struct BatchSwapStep {
        bytes32 poolId;
        uint assetInIndex;
        uint assetOutIndex;
        uint amount;
        bytes userData;
    }

    function batchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds,
        int[] memory limits,
        uint deadline
    ) external returns (int[] memory assetDeltas);

    enum ExitKind {
        EXACT_BPT_IN_FOR_ONE_TOKEN_OUT,
        EXACT_BPT_IN_FOR_TOKENS_OUT,
        BPT_IN_FOR_EXACT_TOKENS_OUT,
        MANAGEMENT_FEE_TOKENS_OUT // for InvestmentPool
    }

    struct ExitPoolRequest{
        address[] assets;
        uint256[] minAmountsOut;
        bytes userData;
        bool toInternalBalance;
    }

    function exitPool(
        bytes32 poolId,
        address sender,
        address payable recipient,
        ExitPoolRequest memory request
    ) external;

    function getPoolTokens(bytes32 poolId) external view returns (
        address[] memory tokens,
        uint[] memory balances,
        uint lastChangeBlock
    );

    function queryBatchSwap(
        SwapKind kind,
        BatchSwapStep[] memory swaps,
        address[] memory assets,
        FundManagement memory funds
    ) external returns (int256[] memory assetDeltas);
}