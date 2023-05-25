// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';

error InvalidSignature();

/**
 * @title DigiSigHelper
 * @author @NiftyMike | @NFTCulture
 * @dev Helper class for handling ECDSA signatures with OpenZepplin library.
 */
abstract contract DigiSigHelper {
    using ECDSA for bytes32;

    function _verify(
        bytes32 dataHash,
        bytes memory signature,
        address expectedSigner
    ) internal pure returns (bool) {
        address signatureSigner = dataHash.toEthSignedMessageHash().recover(signature);
        if (signatureSigner != expectedSigner) revert InvalidSignature();

        return true;
    }
}