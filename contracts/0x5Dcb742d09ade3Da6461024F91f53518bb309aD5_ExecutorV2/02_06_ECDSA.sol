// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library ECDSA {
    function recover(
        bytes32 hash_,
        bytes memory signature_
    ) internal pure returns (address) {
        require(signature_.length == 65, "standart signature only");

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature_, 32))
            s := mload(add(signature_, 64))
            v := byte(0, mload(add(signature_, 96)))
        }

        if (
            uint256(s) >
            0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
        ) {
            revert("invalid signature 's' value");
        }
        if (v != 27 && v != 28) {
            revert("invalid signature 'v' value");
        }

        address signer = ecrecover(hash_, v, r, s);
        require(signer != address(0), "invalide signature");
        return signer;
    }
}