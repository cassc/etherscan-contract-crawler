// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ILicenseInternal.sol";

interface ILicenseAdmin {
    function setLicenseVersion(ILicenseInternal.LicenseVersion licenseVersion) external;

    function lockLicenseVersion() external;

    function licenseVersionLocked() external view returns (bool);
}