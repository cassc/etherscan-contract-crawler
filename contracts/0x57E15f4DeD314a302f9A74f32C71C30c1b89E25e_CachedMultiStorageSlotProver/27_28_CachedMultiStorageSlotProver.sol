/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./BatchProver.sol";
import "./StateVerifier.sol";
import "../lib/FactSigs.sol";

/**
 * @title CachedMultiStorageSlotProver
 * @author Theori, Inc.
 * @notice CachedMultiStorageSlotProver batch proves multiple storage slots from an account
 *         at a particular block, using a cached account storage root
 */
contract CachedMultiStorageSlotProver is BatchProver, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        BatchProver(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct CachedMultiStorageSlotProof {
        address account;
        uint256 blockNumber;
        bytes32 storageRoot;
        bytes proofNodes;
        bytes32[] slots;
        bytes slotProofs;
    }

    function parseCachedMultiStorageSlotProof(bytes calldata proof)
        internal
        pure
        returns (CachedMultiStorageSlotProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular block.
     *
     * @param encodedProof the encoded CachedMultiStorageSlotProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact[] memory) {
        CachedMultiStorageSlotProof calldata proof = parseCachedMultiStorageSlotProof(encodedProof);
        (bool exists, , ) = reliquary.getFact(
            proof.account,
            FactSigs.accountStorageFactSig(proof.blockNumber, proof.storageRoot)
        );
        require(exists, "Cached storage root doesn't exist");

        BytesCalldata[] memory values = verifyMultiStorageSlot(
            proof.proofNodes,
            proof.slots,
            proof.slotProofs,
            proof.storageRoot
        );

        Fact[] memory facts = new Fact[](values.length);

        for (uint256 i = 0; i < values.length; i++) {
            facts[i] = Fact(
                proof.account,
                FactSigs.storageSlotFactSig(proof.slots[i], proof.blockNumber),
                values[i].convert()
            );
        }
        return facts;
    }
}