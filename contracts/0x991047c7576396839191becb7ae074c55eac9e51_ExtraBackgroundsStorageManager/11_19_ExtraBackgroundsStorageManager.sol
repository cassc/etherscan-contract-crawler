// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
pragma solidity 0.8.16;

import {IBucketStorage} from "solidify-contracts/IBucketStorage.sol";
import {BucketStorageLib, FieldCoordinates} from "solidify-contracts/BucketStorageLib.sol";
import {Compressed} from "solidify-contracts/Compressed.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

import {PublicInflateLibWrapper} from "solidify-contracts/InflateLibWrapper.sol";
import {IndexedBucketLib} from "solidify-contracts/IndexedBucketLib.sol";

import {LayerStorageMapping, LayerType} from "moonbirds-inchain/gen/LayerStorageMapping.sol";
import {LayerStorageDeployer} from "moonbirds-inchain/gen/LayerStorageDeployer.sol";
import {TraitStorageMapping, TraitType} from "moonbirds-inchain/gen/TraitStorageMapping.sol";
import {TraitStorageDeployer} from "moonbirds-inchain/gen/TraitStorageDeployer.sol";

/**
 * @notice Keeps records of deployed BucketStorages that contain extra
 *  background layers. The layer data is accessed using a unique `backgroundId`.
 */
contract ExtraBackgroundsStorageManager is Ownable {
    using IndexedBucketLib for bytes;
    using PublicInflateLibWrapper for Compressed;
    using BucketStorageLib for IBucketStorage[];

    // =========================================================================
    //                           Errors
    // =========================================================================

    error UnsupportedBackgroundId();

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice Bundle of `BucketStorage`s containing artwork layer data.
     */
    IBucketStorage[] internal _bundle;

    // =========================================================================
    //                           Getter
    // =========================================================================

    /**
     * @notice Retrieves a given background layer from storage.
     * @param backgroundId the id of the background to be retrieved. Must be
     * >= 2 because the default (0), and PROOF (1) backgrounds are handled by
     * the standard `AssetStorageManager`.
     * @return Uncompressed layer BGR pixels.
     */
    function loadBackground(uint256 backgroundId)
        public
        view
        returns (bytes memory)
    {
        if (backgroundId < 2) {
            revert UnsupportedBackgroundId();
        }

        uint256 fieldId = backgroundId - 2;

        if (fieldId >= _bundle.numFields()) {
            revert UnsupportedBackgroundId();
        }

        FieldCoordinates memory coordinates = _bundle.locateByAbsoluteFieldId(
            fieldId
        );

        return
            _bundle[coordinates.bucket.storageId]
                .getBucket(coordinates.bucket.bucketId)
                .inflate()
                .getField(coordinates.fieldId);
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Adds a new background bucket storage to the bundle.
     */
    function addBucketStorage(IBucketStorage store) external onlyOwner {
        _bundle.push(store);
    }

    /**
     * @notice Changes an existing bucket storage in the bundle.
     */
    function setBucketStorage(uint256 idx, IBucketStorage store)
        external
        onlyOwner
    {
        _bundle[idx] = store;
    }
}