//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import {ISignature} from "../../interfaces/ISignature.sol";
import {LibSignature} from "../../libraries/LibSignature.sol";

/// @author Amit Molek
/// @dev Please see `ISignature` for docs
contract SignatureFacet is ISignature {
    function verifySigner(
        address signer,
        bytes32 hashToVerify,
        bytes memory signature
    ) external pure override returns (bool) {
        return LibSignature._verifySigner(signer, hashToVerify, signature);
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        external
        pure
        override
        returns (address)
    {
        return LibSignature._recoverSigner(hash, signature);
    }
}