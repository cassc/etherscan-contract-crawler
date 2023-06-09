// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface ICoordinator {
    function inPhase() external view returns (int8);

    function initialize(address[] memory nodes, bytes[] memory publicKeys) external;

    function startBlock() external view returns (uint256);

    function selfDestruct() external;
}