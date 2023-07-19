/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./Prover.sol";
import "./StateVerifier.sol";
import "../lib/FactSigs.sol";

/**
 * @title StorageSlotProver
 * @author Theori, Inc.
 * @notice StorageSlotProver proves that a storage slot had a particular value
 *         at a particular block.
 */
contract StorageSlotProver is Prover, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        Prover(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct StorageSlotProof {
        address account;
        bytes accountProof;
        bytes32 slot;
        bytes slotProof;
        bytes header;
        bytes blockProof;
    }

    function parseStorageSlotProof(bytes calldata proof)
        internal
        pure
        returns (StorageSlotProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular block.
     *
     * @param encodedProof the encoded StorageSlotProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        StorageSlotProof calldata proof = parseStorageSlotProof(encodedProof);
        (
            bool exists,
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.AccountData memory acc
        ) = verifyAccountAtBlock(proof.account, proof.accountProof, proof.header, proof.blockProof);
        require(exists, "Account does not exist at block");

        bytes memory value = verifyStorageSlot(proof.slot, proof.slotProof, acc.StorageRoot);
        return Fact(proof.account, FactSigs.storageSlotFactSig(proof.slot, head.Number), value);
    }
}