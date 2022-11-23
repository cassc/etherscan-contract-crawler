// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import "./storage/LayerBucketStorage0.sol";
import "./storage/LayerBucketStorage1.sol";
import "./storage/LayerBucketStorage2.sol";

library LayerStorageDeployer {
    struct Bundle {
        IBucketStorage[3] storages;
    }

    function deployAsStatic() internal returns (Bundle memory) {
        return Bundle({
            storages: [
                IBucketStorage(new LayerBucketStorage0()),
                IBucketStorage(new LayerBucketStorage1()),
                IBucketStorage(new LayerBucketStorage2())
            ]
        });
    }

    function deployAsDynamic() internal returns (IBucketStorage[] memory bundle) {
        bundle = new IBucketStorage[](3);

        bundle[0] = IBucketStorage(new LayerBucketStorage0());

        bundle[1] = IBucketStorage(new LayerBucketStorage1());

        bundle[2] = IBucketStorage(new LayerBucketStorage2());
    }
}