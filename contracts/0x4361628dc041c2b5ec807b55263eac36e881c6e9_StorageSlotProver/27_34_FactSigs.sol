/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "./Facts.sol";

/**
 * @title FactSigs
 * @author Theori, Inc.
 * @notice Helper functions for computing fact signatures
 */
library FactSigs {
    /**
     * @notice Produce the fact signature data for birth certificates
     */
    function birthCertificateFactSigData() internal pure returns (bytes memory) {
        return abi.encode("BirthCertificate");
    }

    /**
     * @notice Produce the fact signature for a birth certificate fact
     */
    function birthCertificateFactSig() internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, birthCertificateFactSigData());
    }

    /**
     * @notice Produce the fact signature data for an account's storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSigData(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("AccountStorage", blockNum, storageRoot);
    }

    /**
     * @notice Produce a fact signature for an account storage root
     * @param blockNum the block number to look at
     * @param storageRoot the storageRoot for the account
     */
    function accountStorageFactSig(uint256 blockNum, bytes32 storageRoot)
        internal
        pure
        returns (FactSignature)
    {
        return
            Facts.toFactSignature(Facts.NO_FEE, accountStorageFactSigData(blockNum, storageRoot));
    }

    /**
     * @notice Produce the fact signature data for an account's code hash
     * @param blockNum the block number to look at
     * @param codeHash the codeHash for the account
     */
    function accountCodeHashFactSigData(uint256 blockNum, bytes32 codeHash)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("AccountCodeHash", blockNum, codeHash);
    }

    /**
     * @notice Produce a fact signature for an account code hash
     * @param blockNum the block number to look at
     * @param codeHash the codeHash for the account
     */
    function accountCodeHashFactSig(uint256 blockNum, bytes32 codeHash)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, accountCodeHashFactSigData(blockNum, codeHash));
    }

    /**
     * @notice Produce the fact signature data for an account's nonce at a block
     * @param blockNum the block number to look at
     */
    function accountNonceFactSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("AccountNonce", blockNum);
    }

    /**
     * @notice Produce a fact signature for an account nonce at a block
     * @param blockNum the block number to look at
     */
    function accountNonceFactSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, accountNonceFactSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for an account's balance at a block
     * @param blockNum the block number to look at
     */
    function accountBalanceFactSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("AccountBalance", blockNum);
    }

    /**
     * @notice Produce a fact signature for an account balance a block
     * @param blockNum the block number to look at
     */
    function accountBalanceFactSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, accountBalanceFactSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for an account's raw header
     * @param blockNum the block number to look at
     */
    function accountFactSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("Account", blockNum);
    }

    /**
     * @notice Produce a fact signature for an account raw header
     * @param blockNum the block number to look at
     */
    function accountFactSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, accountFactSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSigData(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("StorageSlot", slot, blockNum);
    }

    /**
     * @notice Produce a fact signature for a storage slot
     * @param slot the account's slot
     * @param blockNum the block number to look at
     */
    function storageSlotFactSig(bytes32 slot, uint256 blockNum)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, storageSlotFactSigData(slot, blockNum));
    }

    /**
     * @notice Produce the fact signature data for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSigData(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (bytes memory) {
        return abi.encode("Log", blockNum, txIdx, logIdx);
    }

    /**
     * @notice Produce a fact signature for a log
     * @param blockNum the block number to look at
     * @param txIdx the transaction index in the block
     * @param logIdx the log index in the transaction
     */
    function logFactSig(
        uint256 blockNum,
        uint256 txIdx,
        uint256 logIdx
    ) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, logFactSigData(blockNum, txIdx, logIdx));
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSigData(uint256 blockNum) internal pure returns (bytes memory) {
        return abi.encode("BlockHeader", blockNum);
    }

    /**
     * @notice Produce the fact signature data for a block header
     * @param blockNum the block number
     */
    function blockHeaderSig(uint256 blockNum) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, blockHeaderSigData(blockNum));
    }

    /**
     * @notice Produce the fact signature data for a withdrawal
     * @param blockNum the block number
     * @param index the withdrawal index
     */
    function withdrawalSigData(uint256 blockNum, uint256 index)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode("Withdrawal", blockNum, index);
    }

    /**
     * @notice Produce the fact signature for a withdrawal
     * @param blockNum the block number
     * @param index the withdrawal index
     */
    function withdrawalFactSig(uint256 blockNum, uint256 index)
        internal
        pure
        returns (FactSignature)
    {
        return Facts.toFactSignature(Facts.NO_FEE, withdrawalSigData(blockNum, index));
    }

    /**
     * @notice Produce the fact signature data for an event fact
     * @param eventId The event in question
     */
    function eventFactSigData(uint64 eventId) internal pure returns (bytes memory) {
        return abi.encode("EventAttendance", "EventID", eventId);
    }

    /**
     * @notice Produce a fact signature for a given event
     * @param eventId The event in question
     */
    function eventFactSig(uint64 eventId) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, eventFactSigData(eventId));
    }

    /**
     * @notice Produce the fact signature data for a transaction fact
     * @param transaction the transaction hash to be proven
     */
    function transactionFactSigData(bytes32 transaction) internal pure returns (bytes memory) {
        return abi.encode("Transaction", transaction);
    }

    /**
     * @notice Produce a fact signature for a transaction
     * @param transaction the transaction hash to be proven
     */
    function transactionFactSig(bytes32 transaction) internal pure returns (FactSignature) {
        return Facts.toFactSignature(Facts.NO_FEE, transactionFactSigData(transaction));
    }
}