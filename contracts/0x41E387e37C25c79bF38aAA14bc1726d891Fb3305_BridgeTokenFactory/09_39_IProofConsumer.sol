// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "rainbow-bridge-sol/nearprover/contracts/ProofDecoder.sol";


interface IProofConsumer {
        function parseAndConsumeProof(
        bytes memory proofData,
        uint64 proofBlockHeight
    ) external returns (ProofDecoder.ExecutionStatus memory result);
}