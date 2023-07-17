// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.16;

import "openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import "openzeppelin-contracts/contracts/interfaces/IERC1271.sol";

import "@pwn/PWNErrors.sol";


/**
 * @title PWN Signature Checker
 * @notice Library to check if a given signature is valid for EOAs or contract accounts.
 * @dev This library is a modification of an Open-Zeppelin `SignatureChecker` library extended by a support for EIP-2098 compact signatures.
 */
library PWNSignatureChecker {

    string internal constant VERSION = "1.0";

    /**
     * @dev Function will try to recover a signer of a given signature and check if is the same as given signer address.
     *      For a contract account signer address, function will check signature validity by calling `isValidSignature` function defined by EIP-1271.
     * @param signer Address that should be a `hash` signer or a signature validator, in case of a contract account.
     * @param hash Hash of a signed message that should validated.
     * @param signature Signature of a signed `hash`. Could be empty for a contract account signature validation.
     *                  Signature can be standard (65 bytes) or compact (64 bytes) defined by EIP-2098.
     * @return True if a signature is valid.
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        // Check that signature is valid for contract account
        if (signer.code.length > 0) {
            (bool success, bytes memory result) = signer.staticcall(
                abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
            );
            return
                success &&
                result.length == 32 &&
                abi.decode(result, (bytes32)) == bytes32(IERC1271.isValidSignature.selector);
        }
        // Check that signature is valid for EOA
        else {
            bytes32 r;
            bytes32 s;
            uint8 v;

            // Standard signature data (65 bytes)
            if (signature.length == 65) {
                assembly {
                    r := mload(add(signature, 0x20))
                    s := mload(add(signature, 0x40))
                    v := byte(0, mload(add(signature, 0x60)))
                }
            }
            // Compact signature data (64 bytes) - see EIP-2098
            else if (signature.length == 64) {
                bytes32 vs;

                assembly {
                    r := mload(add(signature, 0x20))
                    vs := mload(add(signature, 0x40))
                }

                s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
                v = uint8((uint256(vs) >> 255) + 27);
            } else {
                revert InvalidSignatureLength(signature.length);
            }

            return signer == ECDSA.recover(hash, v, r, s);
        }
    }

}