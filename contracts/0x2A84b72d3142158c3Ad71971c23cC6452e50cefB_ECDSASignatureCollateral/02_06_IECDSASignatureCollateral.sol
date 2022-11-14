// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IECDSASignatureCollateral {
    function hashingExtractMessage(address to, uint256 amount) external pure returns (bytes32);
    function hashingSetCollateralMessage(address tokenAddress) external pure returns (bytes32);
    function verifyMessage(bytes32 messageHash, uint256 nonce, uint256 timestamp, bytes[] memory signatures) external;
}