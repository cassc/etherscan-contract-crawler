// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.15;

library Bytes {
    uint256 internal constant WORD_SIZE = 32;

    function concat(bytes memory self, bytes memory other) internal pure returns (bytes memory) {
        bytes memory ret = new bytes(self.length + other.length);
        (uint256 src, uint256 srcLen) = fromBytes(self);
        (uint256 src2, uint256 src2Len) = fromBytes(other);
        (uint256 dest, ) = fromBytes(ret);
        uint256 dest2 = dest + srcLen;
        copy(src, dest, srcLen);
        copy(src2, dest2, src2Len);
        return ret;
    }

    function fromBytes(bytes memory bts) internal pure returns (uint256 addr, uint256 len) {
        len = bts.length;
        assembly {
            addr := add(bts, 32)
        }
    }

    function copy(
        uint256 src,
        uint256 dest,
        uint256 len
    ) internal pure {
        // Copy word-length chunks while possible
        for (; len >= WORD_SIZE; len -= WORD_SIZE) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += WORD_SIZE;
            src += WORD_SIZE;
        }

        if (len == 0) return;

        // Copy remaining bytes
        uint256 mask = 256**(WORD_SIZE - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}