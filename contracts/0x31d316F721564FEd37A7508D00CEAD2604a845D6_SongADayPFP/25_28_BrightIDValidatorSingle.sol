// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../BrightIDValidatorBase.sol";

contract BrightIDValidatorSingle is BrightIDValidatorBase {
    address private _verifier;

    constructor(address verifier_, bytes32 context_) BrightIDValidatorBase(context_) {
        _verifier = verifier_;
    }

    /**
     * @dev Set `_verifier` to `verifier_`.
     *
     * Requirements:
     *
     * - the caller must be the owner.
     */
    function setVerifier(address verifier_) external virtual onlyRole(DEFAULT_ADMIN_ROLE) {
        _verifier = verifier_;
    }

    /**
     * @dev Returns the trusted verifier of the BrightID validator.
     */
    function verifier() public view virtual returns (address) {
        return _verifier;
    }

    /**
     * @dev See {IBrightIDValidator-isTrustedValidator}.
     */
    function isTrustedValidator(address signer) public view virtual returns (bool) {
        return _verifier == signer;
    }
}