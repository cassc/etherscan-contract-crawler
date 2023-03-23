pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ICIP {
    function applyForDecryption(
        bytes calldata _knotId,
        address _stakehouse,
        bytes calldata _aesPublicKey
    ) external;
}