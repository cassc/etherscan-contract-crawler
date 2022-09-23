// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISignatureVerifier {
    event UsedNonce(address account, bytes32 nonce, string action);

    function verifyClaim(
        address token,
        address receiver,
        uint256 maxAllowce,
        uint256 amount,
        uint256 nonce,
        bytes memory signature
    ) external returns (bool);

    function verifyPreSaleMint(
        address receiver,
        bytes32[] memory typeMints,
        uint256[] memory quantities,
        uint256 amountAllowce,
        uint256 nonce,
        bytes memory signature
    ) external returns (bool);
}