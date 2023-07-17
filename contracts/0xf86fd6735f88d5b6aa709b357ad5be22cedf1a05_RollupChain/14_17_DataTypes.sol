// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

library DataTypes {
    struct Block {
        bytes32 rootHash;
        bytes32 intentHash; // hash of L2-to-L1 commitment sync transitions
        uint128 blockTime; // blockNum when this rollup block is committed
        uint128 blockSize; // number of transitions in the block
    }

    struct InitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
    }

    struct DepositTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account; // must provide L1 address for "pending deposit" handling
        uint32 accountId; // needed for transition evaluation in case of dispute
        uint32 assetId;
        uint256 amount;
    }

    struct WithdrawTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        address account; // must provide L1 target address for "pending withdraw" handling
        uint32 accountId;
        uint32 assetId;
        uint256 amount;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes signature;
    }

    struct CommitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 assetAmount;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes signature;
    }

    struct UncommitTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 accountId;
        uint32 strategyId;
        uint256 stTokenAmount;
        uint64 timestamp; // Unix epoch (msec, UTC)
        bytes signature;
    }

    struct BalanceSyncTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        int256 newAssetDelta;
    }

    struct CommitmentSyncTransition {
        uint8 transitionType;
        bytes32 stateRoot;
        uint32 strategyId;
        uint256 pendingCommitAmount;
        uint256 pendingUncommitAmount;
    }

    struct AccountInfo {
        address account;
        uint32 accountId; // mapping only on L2 must be part of stateRoot
        uint256[] idleAssets; // indexed by assetId
        uint256[] stTokens; // indexed by strategyId
        uint64 timestamp; // Unix epoch (msec, UTC)
    }

    struct StrategyInfo {
        uint32 assetId;
        uint256 assetBalance;
        uint256 stTokenSupply;
        uint256 pendingCommitAmount;
        uint256 pendingUncommitAmount;
    }

    struct TransitionProof {
        bytes transition;
        uint256 blockId;
        uint32 index;
        bytes32[] siblings;
    }

    // Even when the disputed transition only affects an account without not a strategy
    // (e.g. deposit), or only affects a strategy without an account (e.g. syncBalance),
    // both AccountProof and StrategyProof must be sent to at least give the root hashes
    // of the two separate Merkle trees (account and strategy).
    // Each transition stateRoot = hash(accountStateRoot, strategyStateRoot).
    struct AccountProof {
        bytes32 stateRoot; // for the account Merkle tree
        AccountInfo value;
        uint32 index;
        bytes32[] siblings;
    }

    struct StrategyProof {
        bytes32 stateRoot; // for the strategy Merkle tree
        StrategyInfo value;
        uint32 index;
        bytes32[] siblings;
    }
}