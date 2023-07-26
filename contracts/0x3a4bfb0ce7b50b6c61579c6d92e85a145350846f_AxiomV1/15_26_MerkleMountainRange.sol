// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title  Merkle Mountain Range
/// @author Axiom
/// @notice Library for Merkle Mountain Range data structure
library MerkleMountainRange {
    /// @notice A Merkle mountain range is a data structure for efficiently storing a commitment to a variable length list of bytes32 values.
    /// @param  peaks The peaks of the MMR as a fixed-length array of length 32.
    ///         `peaks` is ordered in *increasing* size of peaks: `peaks[i]` is the Merkle root of a tree of size `2 ** i` corresponding to the `i`th bit of `len` (see @dev for details)
    /// @param  numPeaks The actual number of peaks in the MMR
    /// @param  len The length of the original list that this MMR is a commitment to; the implementation guarantees that `numPeaks = bit_length(len)`
    /// @param  index For external use: keeps track of the current index of this MMR in the ring buffer (see `AxiomV1Core`)
    /// @dev    peaks stores `numPeaks := bit_length(len)` Merkle roots, with
    ///         `peaks[i] = root(list[((len >> i) << i) - 2^i : ((len >> i) << i)])` if 2^i & len != 0, otherwise 0
    ///         where root(single element) = single element, and `list` is the underlying list for the MMR
    ///         Warning: Only use the check `peaks[i] == 0` to determine if `peaks[i]` is undefined if the original list is guaranteed to not contain 0
    ///         (e.g., if the original list is already of hashes)
    ///         Default initialization is to `len = 0`, `numPeaks = 0`, and all `peaks[i] = 0`
    struct MMR {
        // the peaks
        bytes32[32] peaks;
        // bit_length(len) or 0 if len = 0
        uint32 numPeaks;
        // the length of the original list that this MMR is a commitment to, so `peaks` has `bit_length(len)` elements
        uint32 len;
        // the current index in the ring buffer; this is free storage since `numPeaks, len, index` get packed into a single word in EVM storage
        uint32 index;
    }

    /// @notice Copies the MMR to memory
    /// @dev    Only reads the peaks up to `numPeaks`
    /// @param  self The MMR
    /// @return out The MMR in memory
    function clone(MMR storage self) internal view returns (MMR memory out) {
        out.numPeaks = self.numPeaks;
        out.len = self.len;
        out.index = self.index;
        for (uint32 i = 0; i < out.numPeaks; i++) {
            out.peaks[i] = self.peaks[i];
        }
    }

    /// @notice Copies MMR from memory to storage
    /// @dev    Only changes peaks up to `peaksChanged` to limit SSTOREs
    /// @param  self The MMR in storage
    /// @param  peaksChanged Only copy newMMR.peaks[0 : peaksChanged]
    function copyFrom(MMR storage self, MMR memory newMMR, uint32 peaksChanged) internal {
        self.numPeaks = newMMR.numPeaks;
        self.len = newMMR.len;
        self.index = newMMR.index;
        for (uint32 i = 0; i < peaksChanged; i++) {
            self.peaks[i] = newMMR.peaks[i];
        }
    }

    /// @notice Compute the keccak of the concatenated peaks
    /// @param  self The MMR
    /// @return keccak of the concatenated peaks
    function commit(MMR memory self) internal pure returns (bytes32) {
        bytes32[] memory peaks = new bytes32[](self.numPeaks);
        for (uint32 i = 0; i < self.numPeaks; i++) {
            peaks[i] = self.peaks[i];
        }
        return keccak256(abi.encodePacked(peaks));
    }

    /// @notice Append a new element to the underlying list of the MMR
    /// @param  self The MMR
    /// @param  leaf The new element to append
    /// @return peaksChanged self.peaks[0 : peaksChanged] have been changed
    function appendSingle(MMR memory self, bytes32 leaf) internal pure returns (uint32 peaksChanged) {
        uint32 i = 0;
        bytes32 new_peak = leaf;
        uint32 len = self.len;
        while ((len >> i) & 1 == 1) {
            new_peak = keccak256(abi.encodePacked(self.peaks[i], new_peak));
            self.peaks[i] = 0;
            i += 1;
        }
        self.peaks[i] = new_peak;
        self.len += 1;
        if (i >= self.numPeaks) {
            self.numPeaks = i + 1;
        }
        peaksChanged = i + 1;
    }

    /// @notice Append a sequence of new elements to the underlying list of the MMR, in order
    /// @dev    Optimized compared to looping over `appendSingle`
    /// @param  self The MMR
    /// @param  leaves The new elements to append
    /// @return peaksChanged self.peaks[0 : peaksChanged] have been changed
    function append(MMR memory self, bytes32[] memory leaves) internal pure returns (uint32 peaksChanged) {
        uint32 prevLen = self.len;
        // keeps track of running length of `leaves`
        uint32 toAdd = uint32(leaves.length);
        self.len += toAdd;
        uint32 i = 0;
        uint32 shift;
        while (toAdd != 0) {
            // shift records whether there is an existing peak in the range we should hash with
            shift = (prevLen >> i) & 1;
            // if shift, add peaks[i] to beginning of leaves
            // then hash all leaves
            uint32 next_add = (toAdd + shift) >> 1;
            for (uint32 j = 0; j < next_add; j++) {
                bytes32 left;
                bytes32 right;
                if (shift == 1) {
                    left = (j == 0 ? self.peaks[i] : leaves[2 * j - 1]);
                    right = leaves[2 * j];
                } else {
                    left = leaves[2 * j];
                    right = leaves[2 * j + 1];
                }
                leaves[j] = keccak256(abi.encodePacked(left, right));
            }
            // if to_add + shift is odd, the last element is new self.peaks[i], otherwise 0
            if (toAdd & 1 != shift) {
                self.peaks[i] = leaves[toAdd - 1];
            } else if (shift == 1) {
                // if shift == 0 then self.peaks[i] is already 0
                self.peaks[i] = 0;
            }
            toAdd = next_add;
            i += 1;
        }
        if (i > self.numPeaks) {
            self.numPeaks = i;
        }
        peaksChanged = i;
    }
}