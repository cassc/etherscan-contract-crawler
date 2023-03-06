// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IAsset {
    // solhint-disable-previous-line no-empty-blocks
}

library Balancer {
    enum SwapKind {
        GIVEN_IN,
        GIVEN_OUT
    }

    struct FundManagement {
        address sender;
        bool fromInternalBalance;
        address payable recipient;
        bool toInternalBalance;
    }

    struct SingleSwap {
        bytes32 poolId;
        SwapKind kind;
        IAsset assetIn;
        IAsset assetOut;
        uint256 amount;
        bytes userData;
    }
}

interface IBalancerRouter {
    function swap(
        Balancer.SingleSwap memory singleSwap,
        Balancer.FundManagement memory funds,
        uint256 limit,
        uint256 deadline
    ) external payable returns (uint256);
}

interface IBalancerPool {
    function getPoolId() external view returns (bytes32);
}