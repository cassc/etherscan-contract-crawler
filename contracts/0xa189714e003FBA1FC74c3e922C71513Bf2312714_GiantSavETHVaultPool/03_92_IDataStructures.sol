pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface IDataStructures {
    /// @dev Data structure used for ETH2 data reporting
    struct ETH2DataReport {
        bytes blsPublicKey; /// Public key of the validator
        bytes withdrawalCredentials; /// Withdrawal credentials submitted to the beacon chain
        bool slashed; /// Slashing status
        uint64 activeBalance; /// Validator active balance
        uint64 effectiveBalance; /// Validator effective balance
        uint64 exitEpoch; /// Exit epoch of the validator
        uint64 activationEpoch; /// Activation Epoch of the validator
        uint64 withdrawalEpoch; /// Withdrawal Epoch of the validator
        uint64 currentCheckpointEpoch; /// Epoch of the checkpoint during data reporting
    }

    /// @dev Signature over the hash of essential data
    struct EIP712Signature {
        // we are able to pack these two unsigned ints into a
        uint248 deadline; // deadline defined in ETH1 blocks
        uint8 v; // signature component 1
        bytes32 r; // signature component 2
        bytes32 s; // signature component 3
    }

    /// @dev Data Structure used for Accounts
    struct Account {
        address depositor; /// ECDSA address executing the deposit
        bytes blsSignature; /// BLS signature over the SSZ "DepositMessage" container
        uint256 depositBlock; /// Block During which the deposit to EF Deposit Contract was completed
    }

    /// @dev lifecycle status enumeration of the user
    enum LifecycleStatus {
        UNBEGUN,
        INITIALS_REGISTERED,
        DEPOSIT_COMPLETED,
        TOKENS_MINTED,
        EXITED
    }
}