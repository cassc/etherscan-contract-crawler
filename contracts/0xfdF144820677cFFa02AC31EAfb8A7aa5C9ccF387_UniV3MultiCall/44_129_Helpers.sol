// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

library Helpers {
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 vs) {
        require(sig.length == 64, "invalid signature length");
        // solhint-disable no-inline-assembly
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            vs := mload(add(sig, 64))
        }
        // implicitly return (r, vs)
    }
}