// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IWavesCaller {
    function call(
        uint16 executionChainId_,
        string calldata executionContract_,
        string calldata functionName_,
        string[] calldata args_
    ) external;
}