// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8;

// See https://docs.openzeppelin.com/contracts/4.x/utilities#multicall
interface IMulticallableV0 {
    function multicall(bytes[] calldata data) external returns (bytes[] memory results);
}