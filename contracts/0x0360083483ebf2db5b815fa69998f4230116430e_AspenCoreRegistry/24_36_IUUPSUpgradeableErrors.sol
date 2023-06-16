// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IUUPSUpgradeableErrorsV0 {
    error IllegalVersionUpgrade(
        uint256 existingMajorVersion,
        uint256 existingMinorVersion,
        uint256 existingPatchVersion,
        uint256 newMajorVersion,
        uint256 newMinorVersion,
        uint256 newPatchVersion
    );

    error ImplementationNotVersioned(address implementation);
}

interface IUUPSUpgradeableErrorsV1 is IUUPSUpgradeableErrorsV0 {
    error BackwardsCompatibilityBroken(address implementation);
}