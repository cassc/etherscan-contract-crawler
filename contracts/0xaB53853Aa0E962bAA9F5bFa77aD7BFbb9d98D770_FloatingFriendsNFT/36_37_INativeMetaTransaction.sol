// SPDX-License-Identifier: None
pragma solidity ^0.8.2;

interface INativeMetaTransaction {

    function executeMetaTransaction(address userAddress, bytes memory functionSignature,
                                    bytes32 sigR, bytes32 sigS, uint8 sigV) external payable returns (bytes memory);

    function getNonce(address user) external returns (uint256);
}