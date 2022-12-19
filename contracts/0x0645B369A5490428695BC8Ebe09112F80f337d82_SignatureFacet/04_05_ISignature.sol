//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/// @author Amit Molek
/// @dev signature verification helpers.
interface ISignature {
    /// @param signer the account you want to check that signed
    /// @param hashToVerify the EIP712 hash to verify
    /// @param signature the supposed signature of `signer` on `hashToVerify`
    /// @return true if `signer` signed `hashToVerify` using `signature`
    function verifySigner(
        address signer,
        bytes32 hashToVerify,
        bytes memory signature
    ) external pure returns (bool);

    /// @param hash the EIP712 hash
    /// @param signature the account's signature on `hash`
    /// @return the address that signed on `hash`
    function recoverSigner(bytes32 hash, bytes memory signature)
        external
        pure
        returns (address);
}