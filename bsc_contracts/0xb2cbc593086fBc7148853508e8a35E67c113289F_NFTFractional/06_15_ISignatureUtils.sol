// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISignatureUtils {
    function getMessageHash(uint256 poolId,uint256 amount, uint256 nonce, uint256 typeSignature,address sender) external returns (bytes32);
    function getEthSignedMessageHash(bytes32 _messageHash) external returns (bytes32);
    function verify(uint256 poolId,uint256 amount, uint256 nonce,uint256 typeSignature, address sender,address signer,bytes memory signature) external returns (bool);
    function recoverSigner(bytes32 hash, bytes memory signature) external returns (address);
}