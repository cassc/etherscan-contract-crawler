// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IStbtTimelockController {
    function schedule(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 predecessor,
        bytes32 salt,
        uint256 /*delay*/
    ) external;
}