// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

library EnumerableBitMaps {
    function countSet(BitMaps.BitMap storage bitmap, uint256 indexLimit)
    internal
    view
    returns (uint256)
    {
        uint256 count = 0;
        uint256 bucketIndex = 0;
        uint256 bucketLimit = ((indexLimit - 1) >> 8) + 1;
        while (bucketIndex < bucketLimit) {
            uint256 bucketData = bitmap._data[bucketIndex];
            while (bucketData != 0) {
                bucketData &= (bucketData - 1);
                count++;
            }
            bucketIndex++;
        }
        return count;
    }

    function indexOfNth(
        BitMaps.BitMap storage bitmap,
        uint256 n,
        uint256 indexLimit
    )
    internal
    view
    returns (
        bool found,
        uint256 position
    )
    {
        (
        bool bucketFound,
        uint256 bucketIndex,
        uint256 count
        ) = indexOfNthBucket(bitmap, n, indexLimit);

        if (!bucketFound) {
            return (false, 0);
        }

        uint256 bucketData = bitmap._data[bucketIndex];
        for (uint256 i = 0; i < 256; i++) {
            if (bucketData & 1 != 0) {
                count++;
                if (count == n) {
                    return (true, i + bucketIndex * 256);
                }
            }
            bucketData >>= 1;
        }

        return (false, 0);
    }

    function indexOfNthBucket(
        BitMaps.BitMap storage bitmap,
        uint256 n,
        uint256 indexLimit
    )
    internal
    view
    returns (
        bool found,
        uint256 bucketIndex,
        uint256 bucketStartCount
    )
    {
        found = false;
        bucketIndex = 0;
        bucketStartCount = 0;
        uint256 count = 0;
        uint256 bucketLimit = ((indexLimit - 1) >> 8) + 1;
        while (bucketIndex < bucketLimit) {
            uint256 bucketData = bitmap._data[bucketIndex];
            bucketStartCount = count;
            while (bucketData != 0) {
                bucketData &= (bucketData - 1);
                count++;
                if (count == n) {
                    found = true;
                    return (found, bucketIndex, bucketStartCount);
                }
            }
            bucketIndex++;
        }
        return (found, bucketIndex, bucketStartCount);
    }

    function setMulti(
        BitMaps.BitMap storage bitmap,
        uint256 fromIndex,
        uint256 count
    ) internal {
        uint256 index = fromIndex;
        uint256 toIndex = fromIndex + count;
        while (index < toIndex) {
            uint256 bucket = index >> 8;
            uint256 remainingBitOnCount = toIndex - index;
            uint256 bucketBitOnStartIndex = index & 0xff;
            uint256 bucketBitOnCount = 256 - bucketBitOnStartIndex;
            if (bucketBitOnCount > remainingBitOnCount) {
                bucketBitOnCount = remainingBitOnCount;
            }
            uint256 mask = maskN(bucketBitOnCount) << bucketBitOnStartIndex;
            bitmap._data[bucket] |= mask;
            index += bucketBitOnCount;
        }
    }

    function maskN(uint256 n) internal pure returns (uint256) {
        if (n >= 256) {
            return type(uint256).max;
        }
        return (1 << n) - 1;
    }
}