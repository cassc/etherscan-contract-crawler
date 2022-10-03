// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @param data data sent to `externalAddress`
 * @param value Amount or percentage of ETH / token forwarded to `externalAddress`
 * @param externalAddress Address to be called during external call
 * @param checkFunctionSignature The timestamp when the slicer becomes releasable
 * @param execFunctionSignature The timestamp when the slicer becomes transferable
 */

struct Function {
    bytes data;
    uint256 value;
    address externalAddress;
    bytes4 checkFunctionSignature;
    bytes4 execFunctionSignature;
}