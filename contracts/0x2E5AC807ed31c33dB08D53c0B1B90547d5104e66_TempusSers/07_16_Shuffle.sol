// A shuffling algorithm based on https://afnan.io/posts/2019-04-05-explaining-the-hashed-permutation/
// (Original paper: https://graphics.pixar.com/library/MultiJitteredSampling/paper.pdf)

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library Shuffle {
    /// @param idx The index we want to permute. Must be between 0 and len-1.
    /// @param len The domain of the permutation. Must not be 0.
    function permute(
        uint32 idx,
        uint32 len,
        uint32 seed
    ) internal pure returns (uint32 ret) {
        assert(len != 0 && idx < len);
        uint32 mask = getMask(len);
        do {
            idx = hash(idx, mask, seed);
        } while (idx >= len);
        unchecked {
            ret = (idx + seed) % len;
        }
    }

    function getMask(uint32 len) private pure returns (uint32 mask) {
        unchecked {
            mask = len - 1;
            mask |= mask >> 1;
            mask |= mask >> 2;
            mask |= mask >> 4;
            mask |= mask >> 8;
            mask |= mask >> 16;
        }
    }

    function hash(
        uint32 idx,
        uint32 mask,
        uint32 seed
    ) private pure returns (uint32) {
        unchecked {
            idx ^= seed;
            idx *= 0xe170893d;
            idx ^= seed >> 16;
            idx ^= (idx & mask) >> 4;
            idx ^= seed >> 8;
            idx *= 0x0929eb3f;
            idx ^= seed >> 23;
            idx ^= (idx & mask) >> 1;
            idx *= 1 | (seed >> 27);
            idx *= 0x6935fa69;
            idx ^= (idx & mask) >> 11;
            idx *= 0x74dcb303;
            idx ^= (idx & mask) >> 2;
            idx *= 0x9e501cc3;
            idx ^= (idx & mask) >> 2;
            idx *= 0xc860a3df;
            idx &= mask;
            idx ^= idx >> 5;
        }
        return idx;
    }
}