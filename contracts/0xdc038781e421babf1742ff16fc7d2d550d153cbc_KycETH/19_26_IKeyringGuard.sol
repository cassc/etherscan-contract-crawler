// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.14;

/**
 * @notice KeyringGuard implementation that uses immutables and presents a simplified modifier.
 */

interface IKeyringGuard {

    struct KeyringConfig {
        address trustedForwarder;
        address collateralToken;
        address keyringCredentials;
        address policyManager;
        address userPolicies;
        address exemptionsManager;
    }

    event KeyringGuardConfigured(
        address keyringCredentials,
        address policyManager,
        address userPolicies,
        uint32 admissionPolicyId,
        bytes32 universeRule,
        bytes32 emptyRule
    );

    function checkZKPIICache(address observer, address subject) external returns (bool passed);

    function checkTraderWallet(address observer, address subject) external returns (bool passed);

    function isAuthorized(address from, address to) external returns (bool passed);
}