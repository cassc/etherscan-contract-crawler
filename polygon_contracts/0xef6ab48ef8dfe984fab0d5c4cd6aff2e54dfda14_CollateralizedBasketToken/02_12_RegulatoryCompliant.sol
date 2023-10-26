// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../interfaces/compliance/IRegulatoryCompliant.sol";
import "../interfaces/compliance/IVerificationRegistry.sol";

/// @author Solid World
/// @notice A contract that can integrate a verification registry, and offer a uniform way to
/// validate counterparties against the current registry.
/// @dev Function restrictions should be implemented by derived contracts.
abstract contract RegulatoryCompliant is IRegulatoryCompliant {
    address private verificationRegistry;

    modifier validVerificationRegistry(address _verificationRegistry) {
        if (_verificationRegistry == address(0)) {
            revert InvalidVerificationRegistry();
        }

        _;
    }

    constructor(address _verificationRegistry) validVerificationRegistry(_verificationRegistry) {
        _setVerificationRegistry(_verificationRegistry);
    }

    function setVerificationRegistry(address _verificationRegistry)
        public
        virtual
        validVerificationRegistry(_verificationRegistry)
    {
        _setVerificationRegistry(_verificationRegistry);
    }

    function getVerificationRegistry() public view returns (address) {
        return verificationRegistry;
    }

    /// @inheritdoc IRegulatoryCompliant
    function isValidCounterparty(address counterparty, bool _kycRequired) public view returns (bool) {
        IVerificationRegistry registry = IVerificationRegistry(verificationRegistry);
        if (_kycRequired) {
            return registry.isVerifiedAndNotBlacklisted(counterparty);
        }

        return !registry.isBlacklisted(counterparty);
    }

    function _setVerificationRegistry(address _verificationRegistry) internal {
        verificationRegistry = _verificationRegistry;

        emit VerificationRegistryUpdated(_verificationRegistry);
    }
}