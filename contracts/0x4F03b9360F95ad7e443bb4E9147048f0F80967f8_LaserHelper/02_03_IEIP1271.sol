// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.16;

/**
 * @title IEIP1271
 *
 * @notice Interface to call external contracts to validate signature.
 */
interface IEIP1271 {
    /**
     * @notice Should return whether the signature provided is valid for the provided hash.
     *
     * @param hash      Hash of the data to be signed.
     * @param signature Signature byte array associated with hash.
     *
     * MUST return the bytes4 magic value 0x1626ba7e when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     *
     * @return Magic value.
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4);
}