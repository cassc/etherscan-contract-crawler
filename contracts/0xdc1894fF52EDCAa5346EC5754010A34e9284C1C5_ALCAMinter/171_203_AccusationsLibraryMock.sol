// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/utils/AccusationsLibrary.sol";

import "contracts/libraries/parsers/RCertParserLibrary.sol";

contract AccusationsLibraryMock {
    function recoverSigner(
        bytes memory signature,
        bytes memory prefix,
        bytes memory message
    ) public pure returns (address) {
        return AccusationsLibrary.recoverSigner(signature, prefix, message);
    }

    function recoverMadNetSigner(
        bytes memory signature,
        bytes memory message
    ) public pure returns (address) {
        return AccusationsLibrary.recoverMadNetSigner(signature, message);
    }

    function computeUTXOID(bytes32 txHash, uint32 txIdx) public pure returns (bytes32) {
        return AccusationsLibrary.computeUTXOID(txHash, txIdx);
    }

    function recoverGroupSignature(
        bytes calldata bClaimsSigGroup_
    ) public pure returns (uint256[4] memory publicKey, uint256[2] memory signature) {
        (publicKey, signature) = RCertParserLibrary.extractSigGroup(bClaimsSigGroup_, 0);
    }
}