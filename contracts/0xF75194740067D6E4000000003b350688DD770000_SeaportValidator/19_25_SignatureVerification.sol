// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ConsiderationConstants.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { SafeStaticCall } from "./SafeStaticCall.sol";

/**
 * @title SignatureVerification
 * @author 0age
 * @notice SignatureVerification contains logic for verifying signatures.
 */
abstract contract SignatureVerification {
    using SafeStaticCall for address;

    /**
     * @dev Internal view function to verify the signature of an order. An
     *      ERC-1271 fallback will be attempted if either the signature length
     *      is not 64 or 65 bytes or if the recovered signer does not match the
     *      supplied signer. Note that in cases where a 64 or 65 byte signature
     *      is supplied, only standard ECDSA signatures that recover to a
     *      non-zero address are supported.
     *
     * @param signer    The signer for the order.
     * @param digest    The digest to verify the signature against.
     * @param signature A signature from the signer indicating that the order
     *                  has been approved.
     */
    function _isValidSignature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view returns (bool) {
        // Declare r, s, and v signature parameters.
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (signer.code.length > 0) {
            // If signer is a contract, try verification via EIP-1271.
            return _isValidEIP1271Signature(signer, digest, signature);
        } else if (signature.length == 64) {
            // If signature contains 64 bytes, parse as EIP-2098 signature. (r+s&v)
            // Declare temporary vs that will be decomposed into s and v.
            bytes32 vs;

            (r, vs) = abi.decode(signature, (bytes32, bytes32));

            s = vs & EIP2098_allButHighestBitMask;

            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);

            // Ensure v value is properly formatted.
            if (v != 27 && v != 28) {
                return false;
            }
        } else {
            return false;
        }

        // Attempt to recover signer using the digest and signature parameters.
        address recoveredSigner = ecrecover(digest, v, r, s);

        // Disallow invalid signers.
        if (recoveredSigner == address(0) || recoveredSigner != signer) {
            return false;
            // Should a signer be recovered, but it doesn't match the signer...
        }

        return true;
    }

    /**
     * @dev Internal view function to verify the signature of an order using
     *      ERC-1271 (i.e. contract signatures via `isValidSignature`).
     *
     * @param signer    The signer for the order.
     * @param digest    The signature digest, derived from the domain separator
     *                  and the order hash.
     * @param signature A signature (or other data) used to validate the digest.
     */
    function _isValidEIP1271Signature(
        address signer,
        bytes32 digest,
        bytes memory signature
    ) internal view returns (bool) {
        if (
            !signer.safeStaticCallBytes4(
                abi.encodeWithSelector(
                    IERC1271.isValidSignature.selector,
                    digest,
                    signature
                ),
                IERC1271.isValidSignature.selector
            )
        ) {
            return false;
        }
        return true;
    }
}