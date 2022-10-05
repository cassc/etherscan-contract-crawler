// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @title Interface for GovernanceRegistry
 * @author Playground Labs
 */
interface IGovernanceRegistry {
    function governance() external view returns (address);
}