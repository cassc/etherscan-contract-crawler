// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "rainbow-bridge-sol/nearprover/contracts/INearProver.sol";
import "rainbow-bridge-sol/nearprover/contracts/ProofDecoder.sol";
import "rainbow-bridge-sol/nearbridge/contracts/Borsh.sol";

import "./IProofConsumer.sol";

contract ProofConsumer is Ownable, IProofConsumer {
    using Borsh for Borsh.Data;
    using ProofDecoder for Borsh.Data;

    INearProver public prover;
    bytes public nearTokenLocker;

    /// Proofs from blocks that are below the acceptance height will be rejected.
    // If `minBlockAcceptanceHeight` value is zero - proofs from block with any height are accepted.
    uint64 public minBlockAcceptanceHeight;

    // OutcomeReciptId -> Used
    mapping(bytes32 => bool) public usedProofs;

    constructor (
        bytes memory _nearTokenLocker,
        INearProver _prover,
        uint64 _minBlockAcceptanceHeight
    )  {
        require(
            _nearTokenLocker.length > 0,
            "Invalid Near Token Locker address"
        );
        require(address(_prover) != address(0), "Invalid Near prover address");

        nearTokenLocker = _nearTokenLocker;
        prover = _prover;
        minBlockAcceptanceHeight = _minBlockAcceptanceHeight;
    }

    /// Parses the provided proof and consumes it if it's not already used.
    /// The consumed event cannot be reused for future calls.
    function parseAndConsumeProof(
        bytes memory proofData,
        uint64 proofBlockHeight
    ) external onlyOwner override returns (ProofDecoder.ExecutionStatus memory result) {
        require(
            prover.proveOutcome(proofData, proofBlockHeight),
            "Proof should be valid"
        );

        // Unpack the proof and extract the execution outcome.
        Borsh.Data memory borshData = Borsh.from(proofData);
        ProofDecoder.FullOutcomeProof memory fullOutcomeProof = borshData
            .decodeFullOutcomeProof();
        borshData.done();

        require(
            fullOutcomeProof.block_header_lite.inner_lite.height >=
                minBlockAcceptanceHeight,
            "Proof is from the ancient block"
        );

        bytes32 receiptId = fullOutcomeProof
            .outcome_proof
            .outcome_with_id
            .outcome
            .receipt_ids[0];
        require(
            !usedProofs[receiptId],
            "The burn event proof cannot be reused"
        );
        usedProofs[receiptId] = true;

        require(
            keccak256(
                fullOutcomeProof
                    .outcome_proof
                    .outcome_with_id
                    .outcome
                    .executor_id
            ) == keccak256(nearTokenLocker),
            "Can only unlock tokens/set metadata from the linked proof produced on Near blockchain"
        );

        result = fullOutcomeProof.outcome_proof.outcome_with_id.outcome.status;
        require(
            !result.failed,
            "Can't use failed execution outcome for unlocking the tokens or set metadata"
        );
        require(
            !result.unknown,
            "Can't use unknown execution outcome for unlocking the tokens or set metadata"
        );
    }
}