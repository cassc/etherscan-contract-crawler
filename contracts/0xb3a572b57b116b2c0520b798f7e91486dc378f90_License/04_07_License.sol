// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "./LicenseStorage.sol";
import "./LicenseInternal.sol";
import "./ILicense.sol";

/**
 * @title License
 * @notice Add license name and content URI for interacting or holding assets of this contract. Based on a16z's "Can't Be Evil".
 *
 * @custom:type eip-2535-facet
 * @custom:category Legal
 * @custom:provides-interfaces ILicense ICantBeEvil
 */
contract License is ILicense, LicenseInternal {
    function getLicenseURI() external view returns (string memory) {
        return _getLicenseURI();
    }

    function getLicenseName() external view returns (string memory) {
        return _getLicenseName();
    }

    function licenseVersion() external view returns (LicenseVersion) {
        return _licenseVersion();
    }

    function customLicenseURI() external view returns (string memory) {
        return LicenseStorage.layout().customLicenseURI;
    }

    function customLicenseName() external view returns (string memory) {
        return LicenseStorage.layout().customLicenseName;
    }
}