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
 * @title MultiStorageSlotProver
 * @author Theori, Inc.
 * @notice MultiStorageSlotProver batch proves multiple storage slots from an account
 *         at a particular block.
 */
contract MultiStorageSlotProver is BatchProver, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        BatchProver(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct MultiStorageSlotProof {
        address account;
        bytes accountProof;
        bytes header;
        bytes blockProof;
        bytes proofNodes;
        bytes32[] slots;
        bytes slotProofs;
        bool includeHeader;
    }

    function parseMultiStorageSlotProof(bytes calldata proof)
        internal
        pure
        returns (MultiStorageSlotProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular block.
     *
     * @param encodedProof the encoded MultiStorageSlotProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact[] memory) {
        MultiStorageSlotProof calldata proof = parseMultiStorageSlotProof(encodedProof);
        (
            bool exists,
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.AccountData memory acc
        ) = verifyAccountAtBlock(proof.account, proof.accountProof, proof.header, proof.blockProof);
        require(exists, "Account does not exist at block");

        BytesCalldata[] memory values = verifyMultiStorageSlot(
            proof.proofNodes,
            proof.slots,
            proof.slotProofs,
            acc.StorageRoot
        );

        uint256 slotsOffset = proof.includeHeader ? 1 : 0;
        Fact[] memory facts = new Fact[](values.length + slotsOffset);

        if (proof.includeHeader) {
            facts[0] = Fact(address(0), FactSigs.blockHeaderSig(head.Number), abi.encode(head));
        }
        for (uint256 i = 0; i < values.length; i++) {
            facts[slotsOffset + i] = Fact(
                proof.account,
                FactSigs.storageSlotFactSig(proof.slots[i], head.Number),
                values[i].convert()
            );
        }
        return facts;
    }
}