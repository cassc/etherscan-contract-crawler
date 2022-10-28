// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SapphireTypes {

    struct ScoreProof {
        address account;
        bytes32 protocol;
        uint256 score;
        bytes32[] merkleProof;
    }

    struct Vault {
        uint256 collateralAmount;
        uint256 normalizedBorrowedAmount;
        uint256 principal;
    }

    struct RootInfo {
        bytes32 merkleRoot;
        uint256 timestamp;
    }

    enum Operation {
        Deposit,
        Withdraw,
        Borrow,
        Repay,
        Liquidate
    }

    struct Action {
        uint256 amount;
        address borrowAssetAddress;
        Operation operation;
        address userToLiquidate;
    }
}