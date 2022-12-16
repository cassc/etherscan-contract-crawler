// SPDX-License-Identifier: MIT
// Copyright 2022 PROOF Holdings Inc
// GENERATED CODE - DO NOT EDIT
pragma solidity 0.8.16;

import "./storage/TraitBucketStorage0.sol";

library TraitStorageDeployer {
    struct Bundle {
        IBucketStorage[1] storages;
    }

    function deployAsStatic() internal returns (Bundle memory) {
        return Bundle({storages: [IBucketStorage(new TraitBucketStorage0())]});
    }

    function deployAsDynamic() internal returns (IBucketStorage[] memory bundle) {
        bundle = new IBucketStorage[](1);

        bundle[0] = IBucketStorage(new TraitBucketStorage0());
    }
}