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
 * @title CachedStorageSlotProver
 * @author Theori, Inc.
 * @notice CachedStorageSlotProver proves that a storage slot had a particular value
 *         at a particular block, using a cached account storage root
 */
contract CachedStorageSlotProver is Prover, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        Prover(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct CachedStorageSlotProof {
        address account;
        uint256 blockNumber;
        bytes32 storageRoot;
        bytes32 slot;
        bytes slotProof;
    }

    function parseCachedStorageSlotProof(bytes calldata proof)
        internal
        pure
        returns (CachedStorageSlotProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular block.
     *
     * @param encodedProof the encoded CachedStorageSlotProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        CachedStorageSlotProof calldata proof = parseCachedStorageSlotProof(encodedProof);

        (bool exists, , ) = reliquary.getFact(
            proof.account,
            FactSigs.accountStorageFactSig(proof.blockNumber, proof.storageRoot)
        );
        require(exists, "Cached storage root doesn't exist");

        bytes memory value = verifyStorageSlot(proof.slot, proof.slotProof, proof.storageRoot);
        return
            Fact(proof.account, FactSigs.storageSlotFactSig(proof.slot, proof.blockNumber), value);
    }
}