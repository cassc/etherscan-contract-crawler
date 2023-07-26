// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAxiomV1Events {
    /// @notice Emitted when a new batch of consecutive blocks is trustlessly verified and cached in the contract storage `historicalRoots`
    /// @param  startBlockNumber The block number of the first block in the batch
    /// @param  prevHash The parent hash of block `startBlockNumber`
    /// @param  root The Merkle root of hash(i) for i in [0, 1024), where hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
    ///              Otherwise hash(i) = bytes32(0x0) if i >= numFinal
    /// @param  numFinal The number of consecutive blocks in this batch, i.e., [startBlockNumber, startBlockNumber + numFinal) blocks are verified
    event UpdateEvent(uint32 startBlockNumber, bytes32 prevHash, bytes32 root, uint32 numFinal);

    /// @notice Emitted when the size of the historicalMMR changes.
    /// @param  len The historicalMMR now stores commitment to blocks [0, 1024 * len)
    /// @param  index The new index in the ring buffer storing the commitment to historicalMMR
    event MerkleMountainRangeEvent(uint32 len, uint32 index);

    /// @notice Emitted when the SNARK #verifierAddress changes
    /// @param  newAddress The new address of the SNARK verifier contract
    event UpgradeSnarkVerifier(address newAddress);

    /// @notice Emitted when the SNARK #historicalVerifierAddress changes
    /// @param  newAddress The new address of the SNARK historical verifier contract
    event UpgradeHistoricalSnarkVerifier(address newAddress);
}