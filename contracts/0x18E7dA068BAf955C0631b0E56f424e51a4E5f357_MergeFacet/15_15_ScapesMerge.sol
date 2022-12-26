// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

library ScapesMerge {
    struct MergePart {
        uint256 tokenId;
        bool flipX;
        bool flipY;
    }

    struct Merge {
        MergePart[] parts;
        bool isFade;
    }

    function toId(Merge memory merge_) internal pure returns (uint256 mergeId) {
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            MergePart memory part = merge_.parts[i];
            uint256 partDNA = part.tokenId;
            if (part.flipX) {
                partDNA |= 1 << 14;
            }
            if (part.flipY) {
                partDNA |= 1 << 15;
            }
            mergeId |= partDNA << (16 * i);
        }
        mergeId = mergeId << 1;
        if (merge_.isFade) {
            mergeId |= 1;
        }
    }

    function fromId(uint256 mergeId)
        internal
        pure
        returns (Merge memory merge_)
    {
        MergePart[15] memory parts;
        merge_.isFade = mergeId & 1 > 0;
        mergeId >>= 1;
        uint256 numParts;
        for (uint256 i = 0; i < 15; i++) {
            MergePart memory part = parts[i];
            uint256 offset = 16 * i;
            uint256 filter = (1 << (offset + 14)) - (1 << offset);
            part.tokenId = (mergeId & filter) >> offset;
            if (part.tokenId == 0) {
                break;
            }
            part.flipX = mergeId & (1 << (offset + 14)) > 0;
            part.flipY = mergeId & (1 << (offset + 15)) > 0;
            numParts++;
        }
        merge_.parts = new MergePart[](numParts);
        for (uint256 i = 0; i < numParts; i++) {
            merge_.parts[i] = parts[i];
        }
    }

    function getSortedTokenIds(Merge memory merge_, bool unique)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory tokenIds = new uint256[](merge_.parts.length);
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            tokenIds[i] = merge_.parts[i].tokenId;
        }
        _quickSort(tokenIds, int256(0), int256(tokenIds.length - 1));
        if (!unique) {
            return tokenIds;
        }
        uint256 uniqueCounter;
        uint256 lastTokenId;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != lastTokenId) uniqueCounter++;
            lastTokenId = tokenIds[i];
        }

        uint256[] memory uniqueTokenIds = new uint256[](uniqueCounter);
        uniqueCounter = 0;
        lastTokenId = 0;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] != lastTokenId) {
                uniqueTokenIds[uniqueCounter] = tokenIds[i];
                uniqueCounter++;
            }
        }
        return uniqueTokenIds;
    }

    function hasNoFlip(Merge memory merge_) internal pure returns (bool) {
        for (uint256 i = 0; i < merge_.parts.length; i++) {
            if (merge_.parts[i].flipX || merge_.parts[i].flipY) return false;
        }
        return true;
    }

    // Sorts in-place
    function _quickSort(
        uint256[] memory arr,
        int256 left,
        int256 right
    ) internal pure {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) _quickSort(arr, left, j);
        if (i < right) _quickSort(arr, i, right);
    }
}