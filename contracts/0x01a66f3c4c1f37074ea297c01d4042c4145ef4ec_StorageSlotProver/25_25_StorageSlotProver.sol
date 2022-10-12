/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./StateVerifier.sol";
import "../lib/FactSigs.sol";

/**
 * @title StorageSlotProver
 * @author Theori, Inc.
 * @notice StorageSlotProver proves that a storage slot had a particular value
 *         at a particular block.
 */
contract StorageSlotProver is StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    /**
     * @notice Proves that a storage slot had a particular value at a particular
     *         block.
     *
     * @param account the account to prove exists
     * @param accountProof the Merkle-Patricia trie proof for the account
     * @param slot the storage slot index
     * @param slotProof the Merkle-Patricia trie proof for the slot
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     */
    function proveStorageSlot(
        address account,
        bytes calldata accountProof,
        bytes32 slot,
        bytes calldata slotProof,
        bytes calldata header,
        bytes calldata blockProof
    ) public payable returns (uint256, bytes memory) {
        reliquary.checkProveFactFee{value: msg.value}(msg.sender);

        (
            bool exists,
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.AccountData memory acc
        ) = verifyAccountAtBlock(account, accountProof, header, blockProof);
        require(exists, "Account does not exist at block");

        bytes memory value = verifyStorageSlot(slot, slotProof, acc.StorageRoot);
        return (head.Number, value);
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular
     *         block, and stores this fact in the reliquary.
     *
     * @param account the account to prove exists
     * @param accountProof the Merkle-Patricia trie proof for the account
     * @param slot the storage slot index
     * @param slotProof the Merkle-Patricia trie proof for the slot
     * @param header the block header, RLP encoded
     * @param blockProof proof that the block header is valid
     */
    function proveAndStoreStorageSlot(
        address account,
        bytes calldata accountProof,
        bytes32 slot,
        bytes calldata slotProof,
        bytes calldata header,
        bytes calldata blockProof
    ) external payable returns (uint256 blockNum, bytes memory value) {
        (blockNum, value) = proveStorageSlot(
            account,
            accountProof,
            slot,
            slotProof,
            header,
            blockProof
        );
        reliquary.setFact(account, FactSigs.storageSlotFactSig(slot, blockNum), value);
    }
}