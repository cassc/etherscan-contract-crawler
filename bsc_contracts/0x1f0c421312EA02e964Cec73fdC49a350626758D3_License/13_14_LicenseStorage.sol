// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ILicenseInternal.sol";

library LicenseStorage {
    struct Layout {
        ILicenseInternal.LicenseVersion licenseVersion;
        string customLicenseURI;
        string customLicenseName;
        bool licenseVersionLocked;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("v2.flair.contracts.storage.License");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}