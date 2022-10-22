// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../access/ownable/OwnableInternal.sol";

import "./LicenseStorage.sol";
import "./LicenseInternal.sol";
import "./ILicenseAdmin.sol";

/**
 * @title License - Admin - Ownable
 * @notice Allow contract owner to manage license version, name and URI.
 *
 * @custom:type eip-2535-facet
 * @custom:category Legal
 * @custom:peer-dependencies ILicense ICantBeEvil
 * @custom:provides-interfaces ILicenseAdmin
 */
contract LicenseOwnable is ILicenseAdmin, OwnableInternal, LicenseInternal {
    using LicenseStorage for LicenseStorage.Layout;

    function setLicenseVersion(LicenseVersion licenseVersion) external override onlyOwner {
        _setLicenseVersion(licenseVersion);
    }

    function lockLicenseVersion() external override onlyOwner {
        _lockLicenseVersion();
    }

    function licenseVersionLocked() external view override returns (bool) {
        return LicenseStorage.layout().licenseVersionLocked;
    }
}