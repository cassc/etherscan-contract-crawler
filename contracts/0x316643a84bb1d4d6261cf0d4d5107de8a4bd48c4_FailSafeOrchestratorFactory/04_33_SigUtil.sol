// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/**
 * @dev used to support in contract signature varification.
 * Enables withdraw from FaiSafeWallet while end user pays 
 * for gas.
 * 
 */
abstract contract SigUtil {
    function genSigHash(
        address tokAddr,
        address emergencyWallet,
        uint tokUnit,
        uint expiryBlockNum,
        uint count
    ) public pure returns (bytes32) {
        bytes32 _messageHash = keccak256(
            abi.encodePacked(tokAddr, emergencyWallet, tokUnit, expiryBlockNum, count)
        );
        return _messageHash;
    }

    function prepHashForSig(bytes32 msgHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
    }

    function recomputeAndRecoverSigner(
        address tokAddr,
        address emergencyWallet,
        uint tokUnit,
        uint expiryBlockNum,
        uint count,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 ethSignedMessageHash = prepHashForSig(
            genSigHash(tokAddr, emergencyWallet, tokUnit, expiryBlockNum, count)
        );
        return recoverSigner(ethSignedMessageHash, signature);
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}