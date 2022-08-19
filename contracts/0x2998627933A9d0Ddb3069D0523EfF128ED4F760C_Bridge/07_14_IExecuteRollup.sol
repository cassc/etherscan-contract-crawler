// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IExecuteRollup {
    function executeRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 state
    ) external;
}