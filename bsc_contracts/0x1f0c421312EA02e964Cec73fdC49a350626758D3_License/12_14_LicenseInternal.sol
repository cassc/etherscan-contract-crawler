// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./LicenseStorage.sol";
import "./ILicenseInternal.sol";

/**
 * @title Functionality to expose license name and URI for the assets of the contract.
 */
abstract contract LicenseInternal is ILicenseInternal {
    using Strings for uint256;
    using LicenseStorage for LicenseStorage.Layout;

    string internal constant A16Z_BASE_LICENSE_URI = "ar://_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/";

    function _licenseVersion() internal view virtual returns (ILicenseInternal.LicenseVersion) {
        return LicenseStorage.layout().licenseVersion;
    }

    function _getLicenseURI() internal view virtual returns (string memory) {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersion == LicenseVersion.CUSTOM) {
            return l.customLicenseURI;
        }
        if (l.licenseVersion == LicenseVersion.UNLICENSED) {
            return "";
        }

        return string.concat(A16Z_BASE_LICENSE_URI, uint256(l.licenseVersion).toString());
    }

    function _getLicenseName() internal view virtual returns (string memory) {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersion == LicenseVersion.CUSTOM) {
            return l.customLicenseName;
        }

        if (l.licenseVersion == LicenseVersion.UNLICENSED) {
            return "";
        }

        if (LicenseVersion.CBE_CC0 == l.licenseVersion) return "CBE_CC0";
        if (LicenseVersion.CBE_ECR == l.licenseVersion) return "CBE_ECR";
        if (LicenseVersion.CBE_NECR == l.licenseVersion) return "CBE_NECR";
        if (LicenseVersion.CBE_NECR_HS == l.licenseVersion) return "CBE_NECR_HS";
        if (LicenseVersion.CBE_PR == l.licenseVersion) return "CBE_PR";
        else return "CBE_PR_HS";
    }

    function _setCustomLicense(string calldata _customLicenseName, string calldata _customLicenseURI) internal virtual {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersionLocked) {
            revert ErrLicenseLocked();
        }

        l.licenseVersion = LicenseVersion.CUSTOM;
        l.customLicenseName = _customLicenseName;
        l.customLicenseURI = _customLicenseURI;

        emit CustomLicenseSet(_customLicenseName, _customLicenseURI);
    }

    function _setLicenseVersion(LicenseVersion _newVersion) internal virtual {
        LicenseStorage.Layout storage l = LicenseStorage.layout();

        if (l.licenseVersionLocked) {
            revert ErrLicenseLocked();
        }

        l.licenseVersion = _newVersion;

        emit LicenseVersionSet(_newVersion);
    }

    function _lockLicenseVersion() internal virtual {
        LicenseStorage.layout().licenseVersionLocked = true;

        emit LicenseLocked();
    }
}