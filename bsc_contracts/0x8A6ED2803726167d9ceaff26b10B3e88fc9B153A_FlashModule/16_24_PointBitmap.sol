// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

library PointBitmap {

    function MSB(uint256 number) internal pure returns (uint8 msb) {
        require(number > 0);

        if (number >= 0x100000000000000000000000000000000) {
            number >>= 128;
            msb += 128;
        }
        if (number >= 0x10000000000000000) {
            number >>= 64;
            msb += 64;
        }
        if (number >= 0x100000000) {
            number >>= 32;
            msb += 32;
        }
        if (number >= 0x10000) {
            number >>= 16;
            msb += 16;
        }
        if (number >= 0x100) {
            number >>= 8;
            msb += 8;
        }
        if (number >= 0x10) {
            number >>= 4;
            msb += 4;
        }
        if (number >= 0x4) {
            number >>= 2;
            msb += 2;
        }
        if (number >= 0x2) msb += 1;
    }

    function LSB(uint256 number) internal pure returns (uint8 msb) {
        require(number > 0);

        msb = 255;
        if (number & type(uint128).max > 0) {
            msb -= 128;
        } else {
            number >>= 128;
        }
        if (number & type(uint64).max > 0) {
            msb -= 64;
        } else {
            number >>= 64;
        }
        if (number & type(uint32).max > 0) {
            msb -= 32;
        } else {
            number >>= 32;
        }
        if (number & type(uint16).max > 0) {
            msb -= 16;
        } else {
            number >>= 16;
        }
        if (number & type(uint8).max > 0) {
            msb -= 8;
        } else {
            number >>= 8;
        }
        if (number & 0xf > 0) {
            msb -= 4;
        } else {
            number >>= 4;
        }
        if (number & 0x3 > 0) {
            msb -= 2;
        } else {
            number >>= 2;
        }
        if (number & 0x1 > 0) msb -= 1;
    }

    /// @notice Flips the initialized state for a given point from false to true, or vice versa
    /// @param self The mapping in which to flip the point
    /// @param point The point to flip
    /// @param pointDelta The spacing between usable points
    function flipPoint(
        mapping(int16 => uint256) storage self,
        int24 point,
        int24 pointDelta
    ) internal {
        require(point % pointDelta == 0);
        int24 mapPt = point / pointDelta;
        int16 wordIdx = int16(mapPt >> 8);
        uint8 bitIdx = uint8(uint24(mapPt % 256));
        self[wordIdx] ^= 1 << bitIdx;
    }

    function setOne(
        mapping(int16 => uint256) storage self,
        int24 point,
        int24 pointDelta
    ) internal {
        require(point % pointDelta == 0);
        int24 mapPt = point / pointDelta;
        int16 wordIdx = int16(mapPt >> 8);
        uint8 bitIdx = uint8(uint24(mapPt % 256));
        self[wordIdx] |= 1 << bitIdx;
    }

    function setZero(
        mapping(int16 => uint256) storage self,
        int24 point,
        int24 pointDelta
    ) internal {
        require(point % pointDelta == 0);
        int24 mapPt = point / pointDelta;
        int16 wordIdx = int16(mapPt >> 8);
        uint8 bitIdx = uint8(uint24(mapPt % 256));
        self[wordIdx] &= ~(1 << bitIdx);
    }

    // find nearest one from point, or boundary in the same word
    function nearestLeftOneOrBoundary(
        mapping(int16 => uint256) storage self,
        int24 point,
        int24 pointDelta
    ) internal view returns (int24 left) {
        int24 mapPt = point / pointDelta;
        if (point < 0 && point % pointDelta != 0) mapPt--; // round towards negative infinity

        int16 wordIdx = int16(mapPt >> 8);
        uint8 bitIdx = uint8(uint24(mapPt % 256));
        
        uint256 ones = self[wordIdx] & ((1 << bitIdx) - 1 + (1 << bitIdx));

        left = (ones != 0)
            ? (mapPt - int24(uint24(bitIdx - MSB(ones)))) * pointDelta
            : (mapPt - int24(uint24(bitIdx))) * pointDelta;
        
    }
    
    // find nearest one from point, or boundary in the same word
    function nearestRightOneOrBoundary(
        mapping(int16 => uint256) storage self,
        int24 point,
        int24 pointDelta
    ) internal view returns (int24 right) {
        int24 mapPt = point / pointDelta;
        if (point < 0 && point % pointDelta != 0) mapPt--; // round towards negative infinity

        mapPt += 1;
        int16 wordIdx = int16(mapPt >> 8);
        uint8 bitIdx = uint8(uint24(mapPt % 256));
        
        uint256 ones = self[wordIdx] & (~((1 << bitIdx) - 1));

        right = (ones != 0)
            ? (mapPt + int24(uint24(LSB(ones) - bitIdx))) * pointDelta
            : (mapPt + int24(uint24(type(uint8).max - bitIdx))) * pointDelta;
    }

}