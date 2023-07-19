// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

error MaxBPS(uint256 sent, uint256 maxAllowed);
error ETHTransferFail(address to, uint256 amount);
error ETHMismatch(uint256 sent, uint256 expected);
error InvalidSignature(address signer);