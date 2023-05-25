// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

library SignatureValidator {
    /**
     * @dev Recover signer address from a message
     * by using their signature and return whether the signature is valid
     */
    function verify(bytes32 hashStruct, address signer, bytes memory signature, bytes32 domainSeparator) internal view returns (bool) {
        bytes32 digest = ECDSA.toTypedDataHash(domainSeparator, hashStruct);
        if (Address.isContract(signer)) {
            return
                IERC1271(signer).isValidSignature(digest, signature) == 0x1626ba7e;
        } else {
            return ECDSA.recover(digest, signature) == signer;
        }
    }
}