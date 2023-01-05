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
 * @title AccountStorageProver
 * @author Theori, Inc.
 * @notice AccountStorageProver proves an account's storage root at a particular block
 */
contract AccountStorageProver is Prover, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        Prover(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct AccountStorageProof {
        address account;
        bytes accountProof;
        bytes header;
        bytes blockProof;
    }

    function parseAccountStorageProof(bytes calldata proof)
        internal
        pure
        returns (AccountStorageProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a storage slot had a particular value at a particular block.
     *
     * @param encodedProof the encoded AccountStorageProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        AccountStorageProof calldata proof = parseAccountStorageProof(encodedProof);
        (
            bool exists,
            CoreTypes.BlockHeaderData memory head,
            CoreTypes.AccountData memory acc
        ) = verifyAccountAtBlock(proof.account, proof.accountProof, proof.header, proof.blockProof);
        require(exists, "Account does not exist at block");

        return
            Fact(proof.account, FactSigs.accountStorageFactSig(head.Number, acc.StorageRoot), "");
    }
}