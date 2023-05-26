// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity ^0.8.16;

import {ECDSA} from "openzeppelin-contracts/utils/cryptography/ECDSA.sol";
import {
    SignatureChecker, EnumerableSet
} from "ethier/crypto/SignatureChecker.sol";

/**
 * @notice Introduces claimability based on signed allowances.
 */
abstract contract ClaimableWithSignature {
    using SignatureChecker for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    /**
     * @notice Message struct to allow `numMax` claims for `receiver`.
     */
    struct Allowance {
        address receiver;
        uint16 numMax;
        uint256 nonce;
        uint256 activeAfterTimestamp;
    }

    /**
     * @notice Encodes an approved allowance (i.e. signed by an authorised
     * signer).
     */
    struct SignedAllowance {
        Allowance allowance;
        bytes signature;
    }

    /**
     * @notice Encodes an claim from a given signed allowance, partially
     * consuming the given allowance.
     */
    struct Claim {
        SignedAllowance signedAllowance;
        uint256 num;
    }

    // =========================================================================
    //                           Errors
    // =========================================================================

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
     * @notice Tracks how often a signed allowance has been used to claim.
     */
    mapping(bytes32 => uint256) private _numClaimsByAllowanceDigest;

    // =========================================================================
    //                           Claiming
    // =========================================================================

    /**
     * @notice Computes the hash of a given allowance.
     * @dev This is the raw bytes32 message that will finally be signed by oen
     * of the `_signers`.
     */
    function _digest(Allowance calldata allowance)
        internal
        view
        returns (bytes32)
    {
        // We do not use EIP712 signatures here for the time being for
        // simplicity (and since we will be the only ones signing).
        return SignatureChecker.generateMessage(
            abi.encodePacked(
                allowance.receiver,
                allowance.nonce,
                allowance.numMax,
                allowance.activeAfterTimestamp,
                // Adding chain id and the verifying contract address to prevent
                // replay attacks.
                block.chainid,
                address(this)
            )
        );
    }

    /**
     * @notice Returns the number of claims that have already been redeemed from
     * a given allowance.
     */
    function numAlreadyClaimedWithSignature(Allowance calldata allowance)
        external
        view
        returns (uint256)
    {
        return _numClaimsByAllowanceDigest[_digest(allowance)];
    }

    /**
     * @notice Interface to perform claims with signed allowances.
     * @dev Reverts if the allowances are not correctly signed by an approved
     * signer.
     */
    function claimWithSignatures(Claim[] calldata claims) external payable {
        for (uint256 i; i < claims.length; ++i) {
            _claimWithSignature(claims[i]);
        }
    }

    /**
     * @notice Processes the claim with a given signature.
     * @dev Reverts if the allowances are not correctly signed by an approved
     * signer.
     */
    function _claimWithSignature(Claim calldata claim) internal virtual {
        _beforeClaimWithSignature(claim);
        _validateClaimWithSignature(claim);
        _doClaimFromSignature(
            claim.signedAllowance.allowance.receiver, claim.num
        );
    }

    /**
     * @notice Hook called by `_claimWithSignature` before claiming from
     * signatures.
     * @dev Intended to add more checks required by the inheriting contract
     * (e.g. total claim limit).
     */
    function _beforeClaimWithSignature(Claim calldata claim) internal virtual {}

    /**
     * @notice Validates a given claim, i.e. signature validity and the number
     * of claims that have already been performed.
     */
    function _validateClaimWithSignature(Claim calldata claim)
        internal
        virtual
    {
        if (
            block.timestamp // solhint-disable-line not-rely-on-time
                < claim.signedAllowance.allowance.activeAfterTimestamp
        ) {
            revert AllowanceNotActive(claim.signedAllowance.allowance);
        }

        bytes32 digest = _digest(claim.signedAllowance.allowance);
        _signers.requireValidSignature(digest, claim.signedAllowance.signature);

        uint256 numLeft = claim.signedAllowance.allowance.numMax
            - _numClaimsByAllowanceDigest[digest];
        if (numLeft < claim.num) {
            revert TooManyClaimsRequested(
                claim.signedAllowance.allowance, numLeft
            );
        }
        _numClaimsByAllowanceDigest[digest] += claim.num;
    }

    /**
     * @notice Hook called by `_claim` to preform the airdrop for a given
     * moonbird (e.g. minting a voucher token to the caller).
     */
    function _doClaimFromSignature(address receiver, uint256 num)
        internal
        virtual;

    // =========================================================================
    //                           Steering
    // =========================================================================

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
}