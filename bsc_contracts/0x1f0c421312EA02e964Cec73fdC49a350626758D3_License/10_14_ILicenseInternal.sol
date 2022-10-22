// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.15;

interface ILicenseInternal {
    enum LicenseVersion {
        CBE_CC0,
        CBE_ECR,
        CBE_NECR,
        CBE_NECR_HS,
        CBE_PR,
        CBE_PR_HS,
        CUSTOM,
        UNLICENSED
    }

    error ErrLicenseLocked();

    event CustomLicenseSet(string customLicenseURI, string customLicenseName);
    event LicenseVersionSet(LicenseVersion licenseVersion);
    event LicenseLocked();
}