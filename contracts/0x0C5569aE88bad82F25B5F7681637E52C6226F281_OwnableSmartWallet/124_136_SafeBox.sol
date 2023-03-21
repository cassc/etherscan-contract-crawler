pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ICIP } from "../../interfaces/ICIP.sol";

contract SafeBox is ICIP {
    event applyForDecryptionSuccess();

    function applyForDecryption(
        bytes calldata _knotId,
        address _stakehouse,
        bytes calldata _aesPublicKey
    ) external override {
        emit applyForDecryptionSuccess();
    }
}