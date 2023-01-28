// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

function ecdsaRecover(bytes32 messageHash, bytes memory signature) pure returns(address) {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
        r := mload(add(signature, 32))
        s := mload(add(signature, 64))
        v := byte(0, mload(add(signature, 96)))
        if lt(v, 27) {v := add(v, 27)}
    }
    return ecrecover(messageHash, v, r, s);
}