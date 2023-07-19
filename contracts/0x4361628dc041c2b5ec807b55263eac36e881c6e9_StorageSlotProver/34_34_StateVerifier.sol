/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../BlockHistory.sol";
import "../interfaces/IReliquary.sol";
import "../lib/BytesCalldata.sol";
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
    using BytesCalldataOps for bytes;

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
     * @notice verifies that each storage slot is included in the storage trie
     *         using the provided proofs. Accepts both existence and nonexistence
     *         proofs. Reverts if a proof is invalid. Assumes the storageRoot
     *         comes from a valid Ethereum account.
     * @param proofNodes concatenation of all nodes used in the trie proofs
     * @param slots the list of slots being proven
     * @param slotProofs the compressed MPT proofs for each slot
     * @param storageRoot the MPT root hash for the storage trie
     * @return values the values in the storage slot, as bytes, with leading 0 bytes removed
     */
    function verifyMultiStorageSlot(
        bytes calldata proofNodes,
        bytes32[] calldata slots,
        bytes calldata slotProofs,
        bytes32 storageRoot
    ) internal pure returns (BytesCalldata[] memory values) {
        MPT.Node[] memory nodes = MPT.parseNodes(proofNodes);
        MPT.Node[][] memory proofs = MPT.parseCompressedProofs(nodes, slotProofs, slots.length);
        BytesCalldata[] memory results = new BytesCalldata[](slots.length);

        for (uint256 i = 0; i < slots.length; i++) {
            bytes32 key = keccak256(abi.encodePacked(slots[i]));
            (bool exists, bytes calldata value) = MPT.verifyTrieValueWithNodes(
                proofs[i],
                key,
                32,
                storageRoot
            );
            if (exists) {
                (value, ) = RLP.splitBytes(value);
                require(value.length <= 32);
            }
            results[i] = value.convert();
        }
        return results;
    }

    /**
     * @notice verifies that an entry is included in the indexed trie using
     *         the provided proof. Accepts both existence and nonexistence
     *         proofs. Reverts if the proof is invalid. Assumes the root comes
     *         from a valid Ethereum MPT, i.e. from a valid block header.
     *
     * @param idx the receipt index in the block
     * @param proof the MPT proof for the indexed trie
     * @param root the MPT root hash for the indexed trie
     * @return exists whether the index exists
     * @return value the value at the given index, as bytes
     */
    function verifyIndexedTrieProof(
        uint256 idx,
        bytes calldata proof,
        bytes32 root
    ) internal pure returns (bool exists, bytes calldata value) {
        bytes memory key = RLP.encodeUint(idx);
        (exists, value) = MPT.verifyTrieValue(proof, bytes32(key), key.length, root);
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
        (bool exists, bytes calldata receiptValue) = verifyIndexedTrieProof(
            txIdx,
            receiptProof,
            head.ReceiptHash
        );
        require(exists, "receipt does not exist");
        log = CoreTypes.extractLog(receiptValue, logIdx);
    }

    /**
     * @notice verifies the presence of a transaction in the given block at txIdx
     *         using the provided proofs. Reverts if the transaction doesn't exist or if
     *         the proofs are invalid.
     *
     * @param txIdx the transaction index in the block
     * @param transactionProof the Merkle-Patricia trie proof for the transaction's hash
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     * @return head the parsed block header
     * @return txHash the hash of the transaction proven
     */
    function verifyTransactionAtBlock(
        uint256 txIdx,
        bytes calldata transactionProof,
        bytes calldata header,
        bytes calldata blockProof
    ) internal view returns (CoreTypes.BlockHeaderData memory head, bytes32 txHash) {
        head = verifyBlockHeader(header, blockProof);
        (bool exists, bytes calldata txData) = verifyIndexedTrieProof(
            txIdx,
            transactionProof,
            head.TxHash
        );
        require(exists, "transaction does not exist in given block");
        txHash = keccak256(txData);
    }

    /**
     * @notice verifies a withdrawal occurred in the given block using the
     *         provided proofs. Reverts if the withdrawal doesn't exist or
     *         if the proofs are invalid.
     *
     * @param idx the index of the withdrawal in the block
     * @param withdrawalProof the Merkle-Patricia trie proof for the receipt
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     * @return head the parsed block header
     * @return withdrawal the parsed withdrawal value
     */
    function verifyWithdrawalAtBlock(
        uint256 idx,
        bytes calldata withdrawalProof,
        bytes calldata header,
        bytes calldata blockProof
    )
        internal
        view
        returns (CoreTypes.BlockHeaderData memory head, CoreTypes.WithdrawalData memory withdrawal)
    {
        head = verifyBlockHeader(header, blockProof);
        (bool exists, bytes calldata withdrawalValue) = verifyIndexedTrieProof(
            idx,
            withdrawalProof,
            head.WithdrawalsHash
        );
        require(exists, "Withdrawal does not exist at block");
        withdrawal = CoreTypes.parseWithdrawal(withdrawalValue);
    }
}