// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Verifier {
    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }
    // Returns the address that signed a given string message
    function _verifyString(
        bytes32 messageHash,
        Signature memory signature
    ) internal pure returns (address signer) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        return ecrecover(messageDigest, signature.v, signature.r, signature.s);
    }
}