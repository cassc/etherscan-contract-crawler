// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {SignatureChecker} from '@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol';
import {ECDSA} from '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

library SignatureUtil {
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        require(signer != address(0), "SignatureUtil: Invalid signer");
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes32 digest = ECDSA.toTypedDataHash(domainSeparator, hash);
        return SignatureChecker.isValidSignatureNow(signer, digest, signature);
    }
}