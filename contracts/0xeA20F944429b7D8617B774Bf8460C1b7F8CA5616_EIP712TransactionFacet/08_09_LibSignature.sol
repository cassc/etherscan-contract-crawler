//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @author Amit Molek
/// @dev Please see `ISignature` for docs
library LibSignature {
    function _verifySigner(
        address signer,
        bytes32 hashToVerify,
        bytes memory signature
    ) internal pure returns (bool) {
        return (signer == _recoverSigner(hashToVerify, signature));
    }

    function _recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        return ECDSA.recover(hash, signature);
    }
}