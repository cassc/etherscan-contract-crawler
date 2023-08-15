// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

interface IOperatorCollectable {
    function collect(uint256 id, address to) external;

    function markAsCollected(uint256 id) external;
}