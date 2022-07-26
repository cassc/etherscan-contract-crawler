// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import 'hardhat/console.sol';

abstract contract SignatureVerifier {

     function getSigner(bytes32 hash_, bytes memory signature_) public view returns (address, bytes32, bytes32) {
        bytes32 ethSignedHash = getEthSignedMessageHash(hash_);
        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = splitSignature(signature_);
        address addr = ecrecover(ethSignedHash, v, r, s);

        return (addr, hash_, ethSignedHash);
    }

    function getEthSignedMessageHash(bytes32 _messageHash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', _messageHash));
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        require(sig.length == 65);

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }
}