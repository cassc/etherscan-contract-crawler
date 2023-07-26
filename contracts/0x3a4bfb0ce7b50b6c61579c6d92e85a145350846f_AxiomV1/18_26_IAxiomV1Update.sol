// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAxiomV1Update {
    /// @notice Verify and store a batch of consecutive blocks, where the latest block in the batch is within the last 256 most recent blocks.
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract.
    ///         proofData contains public inputs/outputs of
    ///         (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32[11] mmr)
    ///         where the proof verifies the blockhashes of blocks [startBlockNumber, endBlockNumber], endBlockNumber - startBlockNumber <= 1023
    ///         - startBlockNumber must be a multiple of 1024
    ///         - prevHash is the parent hash of block `startBlockNumber`,
    ///         - endHash is the blockhash of block `endBlockNumber`,
    ///         - mmr is the keccak Merkle mountain range of the blockhashes of blocks [startBlockNumber, endBlockNumber], ordered from depth 10 to depth 0
    function updateRecent(bytes calldata proofData) external;

    /// @notice Verify and store a batch of 1024 consecutive blocks,
    ///         where the latest block in the batch is verified against the blockhash cache in #historicalRoots
    /// @dev    The contract checks that #historicalRoots(endBlockNumber + 1) == keccak256(endHash || nextRoot || nextNumFinal)
    ///         where endBlockNumber, endHash are derived from proofData.
    ///         nextRoot and nextNumFinal should be obtained by reading event logs. For old blocks nextNumFinal is _usually_ 1024.
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract. Has same format as in #updateRecent except
    ///         endBlockNumber = startBlockNumber + 1023, so the block batch size is exactly 1024
    ///         mmr contains the keccak Merkle root of the full Merkle tree of depth 10, followed by zeros
    /// @param  nextRoot The Merkle root stored in #historicalRoots(endBlockNumber + 1)
    /// @param  nextNumFinal The numFinal stored in #historicalRoots(endBlockNumber + 1)
    function updateOld(bytes32 nextRoot, uint32 nextNumFinal, bytes calldata proofData) external;

    /// @notice Verify and store a batch of 2^17 = 128 * 1024 consecutive blocks,
    ///         where the latest block in the batch is verified against the blockhash cache in #historicalRoots
    /// @dev    Has the same effect as calling #updateOld 128 times on consecutive batches of 1024 blocks each.
    ///         But uses a different SNARK to verify the proof of all 2^17 blocks at once.
    ///         endHashProofs is used to get the intermediate parent hashes of these 1024 block batches
    /// @param  proofData The raw bytes of a zero knowledge proof to be verified by the contract. Has similar format as in #updateRecent except
    ///         we require endBlockNumber = startBlockNumber + 2^17 - 1, so the block batch size is exactly 2^17.
    ///         proofData contains public inputs/outputs of:
    ///         (bytes32 prevHash, bytes32 endHash, uint32 startBlockNumber, uint32 endBlockNumber, bytes32[18] mmr)
    ///         - startBlockNumber must be a multiple of 1024
    ///         - we require that endBlockNumber - startBlockNumber = 2^17 - 1
    ///         - prevHash is the parent hash of block `startBlockNumber`,
    ///         - endHash is the blockhash of block `endBlockNumber`,
    ///         - mmr[0] is the keccak Merkle root of the blockhashes of blocks [startBlockNumber, startBlockNumber + 2^17), the other entries in mmr are zeros
    /// @param  nextRoot The Merkle root stored in #historicalRoots(endBlockNumber + 1)
    /// @param  nextNumFinal The numFinal stored in #historicalRoots(endBlockNumber + 1)
    /// @param  roots roots[i] is the Merkle root of the blockhashes of blocks [startBlockNumber + i * 1024, startBlockNumber + (i + 1) * 1024) for i = 0, ..., 127
    /// @param  endHashProofs endHashProofs[i] is the Merkle inclusion proof of the blockhash of block `startBlockNumber + (i + 1) * 1024 - 1` in roots[i], for i = 0, ..., 126
    ///         endHashProofs[i][10] is the blockhash of block `startBlockNumber + (i + 1) * 1024 - 1`
    ///         endHashProofs[i][j] is the sibling of the Merkle node at depth j, for j = 0, ..., 9
    function updateHistorical(
        bytes32 nextRoot,
        uint32 nextNumFinal,
        bytes32[128] calldata roots,
        bytes32[11][127] calldata endHashProofs,
        bytes calldata proofData
    ) external;

    /// @notice Extended the stored historical Merkle Mountain Range with a multiple of 1024 blockhash commitments
    /// @dev    The blocks to append must have already been cached by Axiom.
    ///         startBlockNumber must equal historicalMMR.len * 1024, but we make it an input for faster reverts
    /// @param  startBlockNumber The block number of the first block to append
    /// @param  roots roots[i] is the Merkle root of the blockhashes of blocks [startBlockNumber + i * 1024, startBlockNumber + (i + 1) * 1024) for i = 0, ..., roots.length - 1
    /// @param  prevHashes prevHashes[i] is the parent hash of block `startBlockNumber + i * 1024`, for i = 0, ..., roots.length - 1. prevHashes and roots must have the same length.
    function appendHistoricalMMR(uint32 startBlockNumber, bytes32[] calldata roots, bytes32[] calldata prevHashes)
        external;
}