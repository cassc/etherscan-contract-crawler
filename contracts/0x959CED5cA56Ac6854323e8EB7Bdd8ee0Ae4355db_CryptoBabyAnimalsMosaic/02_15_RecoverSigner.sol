// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Functions to verify signature with ECDSA.
 * require : ECDSA.sol
 */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library RecoverSigner {

    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 messageDigest = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32", 
                hash
            )
        );
        return ECDSA.recover(messageDigest, signature);
    }

    function recoverSignerByMsg(string memory message, bytes memory signature) internal pure returns (address) {
        return recoverSigner(keccak256(abi.encodePacked(message)), signature);
    }
}