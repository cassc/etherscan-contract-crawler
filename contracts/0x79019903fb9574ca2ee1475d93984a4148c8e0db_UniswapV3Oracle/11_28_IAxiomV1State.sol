// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IAxiomV1State {
    /// @notice Returns the hash of a batch of consecutive blocks previously verified by the contract
    /// @dev    The reads here will match the emitted #UpdateEvent
    /// @return historicalRoots(startBlockNumber) is 0 unless (startBlockNumber % 1024 == 0)
    ///         historicalRoots(startBlockNumber) = 0 if block `startBlockNumber` is not verified
    ///         historicalRoots(startBlockNumber) = keccak256(prevHash || root || numFinal) where || is concatenation
    ///         - prevHash is the parent hash of block `startBlockNumber`
    ///         - root is the keccak Merkle root of hash(i) for i in [0, 1024), where
    ///             hash(i) is the blockhash of block `startBlockNumber + i` if i < numFinal,
    ///             hash(i) = bytes32(0x0) if i >= numFinal
    ///         - 0 < numFinal <= 1024 is the number of verified consecutive roots in [startBlockNumber, startBlockNumber + numFinal)
    function historicalRoots(uint32 startBlockNumber) external view returns (bytes32);

    /// @notice Returns metadata about the number of consecutive blocks from genesis stored in the contract
    ///         The Merkle mountain range stores a commitment to the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    /// @return numPeaks = bit_length(len) is the number of peaks in the Merkle mountain range
    /// @return len indicates that the historicalMMR commits to blockhashes of blocks [0, 1024 * len)
    /// @return index the current index in the ring buffer storing commitments to historicalMMRs
    function historicalMMR() external view returns (uint32 numPeaks, uint32 len, uint32 index);

    /// @notice Returns the i-th Merkle root in the historical Merkle Mountain Range
    /// @param  i The index, `peaks[i] = root(list[((len >> i) << i) - 2^i : ((len >> i) << i)])` if 2^i & len != 0, otherwise 0
    ///         where root(single element) = single element,
    ///         list is the variable length list where `list[i]` is the Merkle root of the binary tree with leaves the blockhashes of blocks [1024 * i, 1024 * (i + 1))
    function historicalMMRPeaks(uint32 i) external view returns (bytes32);

    /// @notice A ring buffer storing commitments to past historicalMMR states
    /// @param  index The index in the ring buffer
    function mmrRingBuffer(uint256 index) external view returns (bytes32);
}