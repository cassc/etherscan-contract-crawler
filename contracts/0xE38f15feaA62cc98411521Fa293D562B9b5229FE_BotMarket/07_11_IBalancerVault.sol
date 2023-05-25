// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
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

enum SwapKind {
    GIVEN_IN,
    GIVEN_OUT
}

enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    EXACT_BPT_IN_FOR_TOKENS_OUT
}

interface IBalancerVault {
    function joinPool(bytes32 _poolId, address _sender, address _recipient, JoinPoolRequest memory _request)
        external
        payable;

    function swap(SingleSwap memory singleSwap, FundManagement memory funds, uint256 limit, uint256 deadline)
        external
        payable
        returns (uint256);

    function querySwap(SingleSwap memory singleSwap, FundManagement memory funds) external returns (uint256);

    function queryJoin(bytes32 poolId, address sender, address recipient, JoinPoolRequest memory request)
        external
        returns (uint256 bptOut, uint256[] memory amountsIn);
}