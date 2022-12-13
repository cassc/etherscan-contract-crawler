// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SignatureLib {
    struct SignatureData {
        bytes32 root;
        bytes32[] proof;
        bytes signature;
    }

    bytes32 private constant _SIGNATURE_TYPEHASH =
        keccak256("SignatureData(bytes32 root)");

    function hash(SignatureData memory signatureData)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_SIGNATURE_TYPEHASH, signatureData.root));
    }
}