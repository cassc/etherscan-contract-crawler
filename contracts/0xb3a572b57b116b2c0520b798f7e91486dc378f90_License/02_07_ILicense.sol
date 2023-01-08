// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

import "./a16z/ICantBeEvil.sol";
import "./ILicenseInternal.sol";

interface ILicense is ILicenseInternal, ICantBeEvil {
    function licenseVersion() external view returns (ILicenseInternal.LicenseVersion);

    function customLicenseURI() external view returns (string memory);

    function customLicenseName() external view returns (string memory);
}