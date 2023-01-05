/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../BlockHistory.sol";
import "../interfaces/IReliquary.sol";
import "../lib/CoreTypes.sol";
import "../lib/RLP.sol";
import "../lib/MPT.sol";

/**
 * @title StateVerifier
 * @author Theori, Inc.
 * @notice StateVerifier is a base contract for verifying historical Ethereum
 *         state using BlockHistory proofs and MPT proofs.
 */
contract StateVerifier {
    BlockHistory public immutable blockHistory;
    IReliquary private immutable reliquary;

    constructor(BlockHistory _blockHistory, IReliquary _reliquary) {
        blockHistory = _blockHistory;
        reliquary = _reliquary;
    }

    /**
     * @notice verifies that the block header is included in the current chain
     *         by querying the BlockHistory contract using the provided proof.
     *         Reverts if the header or proof is invalid.
     *
     * @param header the block header in RLP encoded form
     * @param proof the proof to pass to blockHistory
     * @return head the parsed block header
     */
    function verifyBlockHeader(bytes calldata header, bytes calldata proof)
        internal
        view
        returns (CoreTypes.BlockHeaderData memory head)
    {
        // first validate the block, ensuring that the rootHash is valid
        (bytes32 blockHash, ) = CoreTypes.getBlockHeaderHashAndSize(header);
        head = CoreTypes.parseBlockHeader(header);
        reliquary.assertValidBlockHashFromProver(
            address(blockHistory),
            blockHash,
            head.Number,
            proof
        );
    }

    /**
     * @notice verifies that the account is included in the account trie using
     *         the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the stateRoot
     *         comes from a valid Ethereum block header.
     *
     * @param account the account address to check
     * @param proof the MPT proof for the account trie
     * @param stateRoot the MPT root hash for the account trie
     * @return exists whether the account exists
     * @return acc the parsed account value
     */
    function verifyAccount(
        address account,
        bytes calldata proof,
        bytes32 stateRoot
    ) internal pure returns (bool exists, CoreTypes.AccountData memory acc) {
        bytes32 key = keccak256(abi.encodePacked(account));

        // validate the trie node and extract the value (if it exists)
        bytes calldata accountValue;
        (exists, accountValue) = MPT.verifyTrieValue(proof, key, 32, stateRoot);
        if (exists) {
            acc = CoreTypes.parseAccount(accountValue);
        }
    }

    /**
     * @notice verifies that the storage slot is included in the storage trie
     *         using the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the storageRoot
     *         comes from a valid Ethereum account.
     *
     * @param slot the storage slot index
     * @param proof the MPT proof for the storage trie
     * @param storageRoot the MPT root hash for the storage trie
     * @return value the value in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyStorageSlot(
        bytes32 slot,
        bytes calldata proof,
        bytes32 storageRoot
    ) internal pure returns (bytes calldata value) {
        bytes32 key = keccak256(abi.encodePacked(slot));

        // validate the trie node and extract the value (default is 0)
        bool exists;
        (exists, value) = MPT.verifyTrieValue(proof, key, 32, storageRoot);
        if (exists) {
            (value, ) = RLP.splitBytes(value);
            require(value.length <= 32);
        }
    }

    /**
     * @notice verifies that the receipt is included in the receipts trie using
     *         the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the receiptsRoot
     *         comes from a valid Ethereum block header.
     *
     * @param idx the receipt index in the block
     * @param proof the MPT proof for the storage trie
     * @param receiptsRoot the MPT root hash for the storage trie
     * @return exists whether the receipt index exists
     * @return value the value in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyReceipt(
        uint256 idx,
        bytes calldata proof,
        bytes32 receiptsRoot
    ) internal pure returns (bool exists, bytes calldata value) {
        bytes memory key = RLP.encodeUint(idx);
        (exists, value) = MPT.verifyTrieValue(proof, bytes32(key), key.length, receiptsRoot);
    }

    /**
     * @notice verifies that the account is included in the account trie for
     *         a block using the provided proofs. Accepts both existence and
     *         nonexistence proofs. Reverts if the proofs are invalid.
     *
     * @param account the account address to check
     * @param accountProof the MPT proof for the account trie
     * @param header the block header in RLP encoded form
     * @param blockProof the proof to pass to blockHistory
     * @return exists whether the account exists
     * @return head the parsed block header
     * @return acc the parsed account value
     */
    function verifyAccountAtBlock(
        address account,
        bytes calldata accountProof,
        bytes calldata header,
        bytes calldata blockProof
    )
        internal
        view
        returns (
            bool exists,
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.AccountData memory acc
        )
    {
        head = verifyBlockHeader(header, blockProof);
        (exists, acc) = verifyAccount(account, accountProof, head.Root);
    }

    /**
     * @notice verifies a log was emitted in the given block, txIdx, and logIdx
     *         using the provided proofs. Reverts if the log doesn't exist or if
     *         the proofs are invalid.
     *
     * @param txIdx the transaction index in the block
     * @param logIdx the index of the log in the transaction
     * @param receiptProof the Merkle-Patricia trie proof for the receipt
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     * @return head the parsed block header
     * @return log the parsed log value
     */
    function verifyLogAtBlock(
        uint256 txIdx,
        uint256 logIdx,
        bytes calldata receiptProof,
        bytes calldata header,
        bytes calldata blockProof
    ) internal view returns (CoreTypes.BlockHeaderData memory head, CoreTypes.LogData memory log) {
        head = verifyBlockHeader(header, blockProof);
        (bool exists, bytes calldata receiptValue) = verifyReceipt(
            txIdx,
            receiptProof,
            head.ReceiptHash
        );
        require(exists, "receipt does not exist");
        log = CoreTypes.extractLog(receiptValue, logIdx);
    }
}