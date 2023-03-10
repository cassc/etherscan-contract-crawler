// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {IMoonbirds} from "moonbirds/IMoonbirds.sol";
import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";

import {
    SignatureChecker, EnumerableSet
} from "ethier/crypto/SignatureChecker.sol";

/**
 * @notice Base contract for airdrops claimable via valid allowance signatures.
 */
abstract contract ClaimableWithSignature {
    using SignatureChecker for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Allows a token to be claimed for the receiver.
     */
    struct Allowance {
        address receiver;
        uint16 numMax;
        uint256 nonce;
        uint256 activeAfterTimestamp;
    }

    /**
     * @notice Encodes an approved allowance.
     */
    struct SignedAllowance {
        Allowance allowance;
        bytes signature;
    }

    /**
     * @notice Encodes an claim from a given signed allowance
     */
    struct Claim {
        SignedAllowance signedAllowance;
        uint16 numClaims;
    }

    // =========================================================================
    //                           Errors
    // =========================================================================

    /**
     * @notice Thrown if the airdrop is not yet open for claims.
     */
    error ClaimWithSignatureDisabled();

    /**
     * @notice Thrown if there are too many requests for a given allowance.
     */
    error TooManyClaimsRequested(Allowance, uint256 numLeft);

    /**
     * @notice Thrown if a given allowance is not active.
     */
    error AllowanceNotActive(Allowance);

    // =========================================================================
    //                           Storage
    // =========================================================================

    /**
     * @notice The set of autorised allowance signers.
     */
    EnumerableSet.AddressSet private _signers;

    /**
     * @notice Tracks how often a siged allowance has been used to claim.
     */
    mapping(bytes32 => uint256) private _numClaimsByAllowanceDigest;

    /**
     * @notice Flag to enable claims with signatures.
     */
    bool private _claimWithSignatureEnabled;

    // =========================================================================
    //                           Airdrop
    // =========================================================================

    /**
     * @notice Computes the hash of a given allowance.
     */
    function _digest(Allowance calldata allowance)
        internal
        view
        returns (bytes32)
    {
        return SignatureChecker.generateMessage(
            abi.encodePacked(
                allowance.receiver,
                allowance.nonce,
                allowance.numMax,
                allowance.activeAfterTimestamp,
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Interface to claim multiple airdrops with given signed
     * allowances.
     * @dev The minted token will always end up on the receiver address
     * specified on the allowances.
     * @dev Reverts if the allowances are not correctly signed by an approved
     * signer.
     */
    function claimMultipleWithSignature(Claim[] calldata claims)
        external
        onlyIfClaimWithSignatureEnabled
    {
        for (uint256 i; i < claims.length; ++i) {
            _claimWithSignature(claims[i].signedAllowance, claims[i].numClaims);
        }
    }

    /**
     * @notice Processes the claim with a given signature.
     * @dev Reverts if the allowances are not correctly signed by an approved
     * signer.
     */
    function _claimWithSignature(
        SignedAllowance calldata signed,
        uint16 numClaims
    ) internal virtual {
        _validateSignedAllowance(signed, numClaims);
        _doClaimsFromSignature(signed.allowance.receiver, numClaims);
    }

    function _validateSignedAllowance(
        SignedAllowance calldata signed,
        uint256 numClaims
    ) internal virtual {
        if (block.timestamp < signed.allowance.activeAfterTimestamp) {
            revert AllowanceNotActive(signed.allowance);
        }

        bytes32 digest = _digest(signed.allowance);
        _signers.requireValidSignature(digest, signed.signature);

        uint256 numLeft =
            signed.allowance.numMax - _numClaimsByAllowanceDigest[digest];
        if (numLeft < numClaims) {
            revert TooManyClaimsRequested(signed.allowance, numLeft);
        }
        _numClaimsByAllowanceDigest[digest] += numClaims;
    }

    /**
     * @notice Returns if the airdrop was already claimed with a given
     * signature.
     */
    function numAlreadyClaimed(Allowance calldata allowance)
        external
        view
        returns (uint256)
    {
        return _numClaimsByAllowanceDigest[_digest(allowance)];
    }

    // =========================================================================
    //                           Steering
    // =========================================================================

    /**
     * @notice Opens the claim of the airdrop.
     */
    function _toggleClaimWithSignature(bool toggle) internal {
        _claimWithSignatureEnabled = toggle;
    }

    /**
     * @notice Changes set of signers authorised to sign allowances.
     */
    function _changeAllowlistSigners(
        address[] calldata rm,
        address[] calldata add
    ) internal {
        for (uint256 i; i < rm.length; ++i) {
            _signers.remove(rm[i]);
        }
        for (uint256 i; i < add.length; ++i) {
            _signers.add(add[i]);
        }
    }

    /**
     * @notice Ensures that a wrapped function can only be called whule the
     * claim with signature is enabled.
     */
    modifier onlyIfClaimWithSignatureEnabled() {
        if (!_claimWithSignatureEnabled) {
            revert ClaimWithSignatureDisabled();
        }
        _;
    }

    // =========================================================================
    //                           Internals
    // =========================================================================

    /**
     * @notice Hook called by `_claim` to preform the airdrop for a given
     * moonbird (e.g. minting a voucher token to the caller).
     */
    function _doClaimsFromSignature(address receiver, uint16 numClaims)
        internal
        virtual;
}