// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IErrors {
    // TODO: Either invalidMintOut or InvalidOutput
    error InvalidMinOut(uint256 minOut);
    error InvalidInput();
    error InvalidOutput();
    error FailedCall(bytes data);
    error InvalidCaller();
    error InvalidFunctionId();
    error InvalidSwapId();
    error InvalidBridgeId();
    error InvalidVault();
    error InvalidHopBridge();
    error NullBalance();
}