// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IERC1271 {
    function isValidSignature(bytes32 _hash, bytes calldata _signature) external view returns (bytes4 magicValue);

    function isValidSignature(
        bytes calldata _message,
        bytes calldata _signature
    ) external view returns (bytes4 magicValue);
}