// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import {BucketCoordinates} from "solidify-contracts/BucketStorageLib.sol";

/**
 * @notice Defines the various types of the lookup.
 */
enum TraitType
/// @dev Valid range [0, 10)
{
    Background,
    /// @dev Valid range [0, 19)
    Beak,
    /// @dev Valid range [0, 112)
    Body,
    /// @dev Valid range [0, 62)
    Eyes,
    /// @dev Valid range [0, 12)
    Eyewear,
    /// @dev Valid range [0, 37)
    Headwear,
    /// @dev Valid range [0, 8)
    Outerwear
}

/**
 * @notice Provides an abstraction layer that allows data to be indexed via
 * (type, index) pairs.
 */
library TraitStorageMapping {
    error InvalidLookup();
    error InvalidTraitType();
    error InvalidTraitIndex(TraitType);

    struct StorageCoordinates {
        BucketCoordinates bucket;
        uint256 fieldId;
    }

    /**
     * @notice Returns the storage coordinates for the given (type, index) pair.
     */
    function locate(TraitType traitType, uint256 index) internal pure returns (StorageCoordinates memory) {
        // See also the definition of `TraitType`.
        uint8[7] memory numTraitsPerTraitType = [10, 19, 112, 62, 12, 37, 8];

        if (index >= numTraitsPerTraitType[uint256(traitType)]) {
            revert InvalidTraitIndex(traitType);
        }

        // First we need to compute the absolute index of the field that we want
        // to retrieve. This is computed by going over the types in the order
        // that they are defined in `TraitType`
        uint256 fieldIdx;

        for (uint256 i; i < 7; ++i) {
            if (i >= uint256(traitType)) {
                break;
            }
            fieldIdx += numTraitsPerTraitType[i];
        }
        fieldIdx += index;

        // Now we need to find the corresponging storage coordinates.
        // The fields in storage follow the same indexing as above if we start
        // our count at the first Bucket of the first BucketStorage. The fields
        // therin will have indices `0.._numFieldsPerBucket(0)[0]`.
        // Then we continue with the second Bucket in the same Storage, and so
        // on. Once we have exhausted all the Buckets in the first Storage, we
        // move on to the next Storage - again starting at the first Bucket.

        StorageCoordinates memory coordinates;

        // With this, it becomes quite easy to find the right coordinates if
        // we know how many fields we have in each BucketStorage ...
        uint16[1] memory numFieldsPerStorage = [260];

        for (uint256 i; i < 1; ++i) {
            uint16 numFields = numFieldsPerStorage[i];
            if (fieldIdx < numFields) {
                coordinates.bucket.storageId = i;
                break;
            }
            fieldIdx -= numFields;
        }

        // ... and Bucket.
        bytes memory numFieldsPerBucket = _numFieldsPerBucket(coordinates.bucket.storageId);
        uint256 numBuckets = numFieldsPerBucket.length;

        for (uint256 i; i < numBuckets; ++i) {
            uint8 numFields = uint8(numFieldsPerBucket[i]);
            if (fieldIdx < numFields) {
                coordinates.bucket.bucketId = i;
                coordinates.fieldId = fieldIdx;
                return coordinates;
            }
            fieldIdx -= numFields;
        }

        revert InvalidTraitType();
    }

    /**
     * @notice Number of fields in each bucket of a given BucketStorage.
     * @dev This has been encoded as `bytes` instead of `uint8[N]` since we
     * cannot return the latter though a common interface without manually
     * converting it to `uint8[]` first.
     */
    function _numFieldsPerBucket(uint256 storageId) private pure returns (bytes memory) {
        if (storageId == 0) {
            return hex"0a13703e0c2508";
        }

        revert InvalidLookup();
    }
}