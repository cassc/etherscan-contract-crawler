// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IEIP1271 {
    // bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;

    /**
     * @notice Legacy EIP1271 method to validate a signature.
     * @param data Arbitrary length data signed on the behalf of address(this).
     * @param signature Signature byte array associated with _data.
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory data, bytes memory signature) external view returns (bytes4);
}