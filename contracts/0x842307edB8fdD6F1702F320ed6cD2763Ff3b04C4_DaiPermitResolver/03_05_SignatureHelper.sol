// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.16;

import {ECDSA} from "../../lib/ECDSA.sol";

struct Signature {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

library SignatureHelper {
    function decomposeSignature(bytes calldata signature_) internal pure returns (Signature memory s) {
        ECDSA.RecoverError err;
        (s.r, s.s, s.v, err) = ECDSA.tryDecompose(signature_);
        require(err == ECDSA.RecoverError.NoError, "SH: signature decompose fail");
    }
}