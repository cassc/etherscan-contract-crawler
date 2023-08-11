/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./StateVerifier.sol";
import "./Prover.sol";
import "../lib/FactSigs.sol";

/**
 * @title BirthCertificateProver
 * @author Theori, Inc.
 * @notice BirthCertificateProver proves that an account existed in a given block
 *         and stores the oldest known account proof in the fact database
 */
contract BirthCertificateProver is Prover, StateVerifier {
    FactSignature public immutable BIRTH_CERTIFICATE_SIG;
    RelicToken immutable token;

    struct AccountProof {
        address account;
        bytes accountProof;
        bytes header;
        bytes blockProof;
    }

    constructor(
        BlockHistory blockHistory,
        IReliquary _reliquary,
        RelicToken _token
    ) Prover(_reliquary) StateVerifier(blockHistory, _reliquary) {
        BIRTH_CERTIFICATE_SIG = FactSigs.birthCertificateFactSig();
        token = _token;
    }

    function parseAccountProof(bytes calldata proof)
        internal
        pure
        returns (AccountProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that an account existed in the given block
     *
     * @param encodedProof the encoded AccountProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        AccountProof calldata proof = parseAccountProof(encodedProof);
        (bool exists, CoreTypes.BlockHeaderData memory head, ) = verifyAccountAtBlock(
            proof.account,
            proof.accountProof,
            proof.header,
            proof.blockProof
        );
        require(exists, "Account does not exist at block");

        (bool proven, , bytes memory data) = reliquary.getFact(
            proof.account,
            BIRTH_CERTIFICATE_SIG
        );

        if (proven) {
            uint48 blockNum = uint48(bytes6(data));
            require(blockNum >= head.Number, "older block already proven");
        }

        data = abi.encodePacked(uint48(head.Number), uint64(head.Time));
        return Fact(proof.account, BIRTH_CERTIFICATE_SIG, data);
    }

    /**
     * @notice handles minting the token after a fact is stored
     *
     * @param fact the fact which was stored
     */
    function _afterStore(Fact memory fact, bool alreadyStored) internal override {
        if (!alreadyStored) {
            token.mint(fact.account, 0);
        }
    }
}