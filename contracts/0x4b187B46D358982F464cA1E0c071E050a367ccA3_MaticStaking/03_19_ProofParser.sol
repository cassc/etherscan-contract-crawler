// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "./CallDataRLPReader.sol";
import "./Utils.sol";

library ProofParser {
    // Proof is message format signed by the protocol. It contains somewhat redundant information, so only part
    // of the proof could be passed into the contract and other part can be inferred from transaction receipt
    struct Proof {
        uint256 chainId;
        uint256 status;
        bytes32 transactionHash;
        uint256 blockNumber;
        bytes32 blockHash;
        uint256 transactionIndex;
        bytes32 receiptHash;
        uint256 transferAmount;
    }

    function parseProof(uint256 proofOffset)
        internal
        pure
        returns (Proof memory)
    {
        Proof memory proof;
        uint256 dataOffset = proofOffset + 0x20;
        assembly {
            calldatacopy(proof, dataOffset, 0x20) // 1 field (chainId)
            dataOffset := add(dataOffset, 0x20)
            calldatacopy(add(proof, 0x40), dataOffset, 0x80) // 4 fields * 0x20 = 0x80
            dataOffset := add(dataOffset, 0x80)
            calldatacopy(add(proof, 0xe0), dataOffset, 0x20) // transferAmount
        }
        return proof;
    }
}