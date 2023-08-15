// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

enum OperationType {
    DEPOSIT,
    REDEEM,
    REBALANCE
}

struct DepositOperationParams {
    address caller;
    address asset;
    uint256 value;
    uint256 mainAssetValue;
    address beneficiary;
    uint8 slippage;
}

struct RedeemOperationParams {
    address caller;
    address asset;
    uint256 shares;
    address beneficiary;
    uint8 slippage;
}

struct RebalanceOperationParams {
    uint256 srcChainId;
    uint256 dstChainId;
    uint256 shareToRebalance;
    uint8 slippage;
}