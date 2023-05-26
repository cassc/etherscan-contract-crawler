// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library Sig {
    function verify(
        bytes memory signature,
        bytes32 digestHash,
        address expected
    ) internal pure returns (bool) {
        address std = getSigner(signature, digestHash);
        if (std == expected) {
            return true;
        }

        address packed = getSignerPacked(signature, digestHash);
        if (packed == expected) {
            return true;
        }

        return false;
    }

    function getSigner(
        bytes memory signature,
        bytes32 digestHash
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        bytes32 signed = getMessageHash(digestHash);
        return ecrecover(signed, v, r, s);
    }

    function getSignerPacked(
        bytes memory signature,
        bytes32 digestHash
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);

        bytes32 signed = getMessageHashPacked(digestHash);
        return ecrecover(signed, v, r, s);
    }

    function getMessageHash(
        bytes32 digestHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode("\x19Ethereum Signed Message:\n32", digestHash)
            );
    }

    function getMessageHashPacked(
        bytes32 digestHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", digestHash)
            );
    }

    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

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