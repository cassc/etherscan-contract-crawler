// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/libraries/math/CryptoLibrary.sol";
import "contracts/libraries/parsers/RCertParserLibrary.sol";

contract CryptoLibraryWrapper {
    function validateSignature(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public view returns (bool, uint256) {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        uint256 gasBefore = gasleft();
        return (
            CryptoLibrary.verifySignature(
                abi.encodePacked(keccak256(bClaims_)),
                signature,
                masterPublicKey
            ),
            gasBefore - gasleft()
        );
    }

    function validateSignatureASM(
        bytes calldata groupSignature_,
        bytes calldata bClaims_
    ) public view returns (bool, uint256) {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        uint256 gasBefore = gasleft();
        return (
            CryptoLibrary.verifySignatureASM(
                abi.encodePacked(keccak256(bClaims_)),
                signature,
                masterPublicKey
            ),
            gasBefore - gasleft()
        );
    }

    function validateBadSignatureASM(
        bytes calldata groupSignature_,
        bytes calldata bClaims_,
        uint256 salt
    ) public view returns (bool, uint256) {
        (uint256[4] memory masterPublicKey, uint256[2] memory signature) = RCertParserLibrary
            .extractSigGroup(groupSignature_, 0);

        uint256 gasBefore = gasleft();
        return (
            CryptoLibrary.verifySignatureASM(
                abi.encodePacked(keccak256(abi.encodePacked(bClaims_, salt))),
                signature,
                masterPublicKey
            ),
            gasBefore - gasleft()
        );
    }
}