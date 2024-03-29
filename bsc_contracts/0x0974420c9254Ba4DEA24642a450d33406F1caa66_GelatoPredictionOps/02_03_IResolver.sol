// SPDX-License-Identifier: BSD-4-Clause

pragma solidity ^0.8.13;

interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}