/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../lib/CoreTypes.sol";
import "../lib/FactSigs.sol";
import "../BlockHistory.sol";
import "./StateVerifier.sol";
import "./Prover.sol";

/**
 * @title BlockHeaderProver
 * @author Theori, Inc.
 * @notice BlockHeaderProver proves that a block header is valid and included in the current chain
 */
contract BlockHeaderProver is Prover, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        Prover(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct BlockHeaderProof {
        bytes header;
        bytes blockProof;
    }

    function parseBlockHeaderProof(bytes calldata proof)
        internal
        pure
        returns (BlockHeaderProof calldata res)
    {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a block header was valid
     *
     * @param encodedProof the encoded BlockHeaderProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        BlockHeaderProof calldata proof = parseBlockHeaderProof(encodedProof);
        CoreTypes.BlockHeaderData memory head = verifyBlockHeader(proof.header, proof.blockProof);
        return Fact(address(0), FactSigs.blockHeaderSig(head.Number), abi.encode(head));
    }
}