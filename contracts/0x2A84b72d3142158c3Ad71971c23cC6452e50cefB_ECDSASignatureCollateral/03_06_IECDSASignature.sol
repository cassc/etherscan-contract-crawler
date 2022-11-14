// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IECDSASignature {
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external;
    function signatureStatus(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external view returns(uint8);
    function checkNonce(uint256 nonce) external view returns (bool);
}