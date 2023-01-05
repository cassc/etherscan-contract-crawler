/// SPDX-License-Identifier: UNLICENSED
/// (c) Theori, Inc. 2022
/// All rights reserved

pragma solidity >=0.8.12;

import "../interfaces/IReliquary.sol";
import "../lib/FactSigs.sol";
import "../RelicToken.sol";
import "../BlockHistory.sol";
import "./Prover.sol";
import "./StateVerifier.sol";

/**
 * @title LogProver
 * @author Theori, Inc.
 * @notice LogProver proves that log events occured in some block.
 */
contract LogProver is Prover, StateVerifier {
    constructor(BlockHistory blockHistory, IReliquary _reliquary)
        Prover(_reliquary)
        StateVerifier(blockHistory, _reliquary)
    {}

    struct LogProof {
        uint256 txIdx;
        uint256 logIdx;
        bytes receiptProof;
        bytes header;
        bytes blockProof;
    }

    function parseLogProof(bytes calldata proof) internal pure returns (LogProof calldata res) {
        assembly {
            res := proof.offset
        }
    }

    /**
     * @notice Proves that a log occured in a block.
     *
     * @param encodedProof the encoded LogProof
     */
    function _prove(bytes calldata encodedProof) internal view override returns (Fact memory) {
        LogProof calldata proof = parseLogProof(encodedProof);
        (CoreTypes.BlockHeaderData memory head, CoreTypes.LogData memory log) = verifyLogAtBlock(
            proof.txIdx,
            proof.logIdx,
            proof.receiptProof,
            proof.header,
            proof.blockProof
        );
        return
            Fact(
                log.Address,
                FactSigs.logFactSig(head.Number, proof.txIdx, proof.logIdx),
                abi.encode(log)
            );
    }
}