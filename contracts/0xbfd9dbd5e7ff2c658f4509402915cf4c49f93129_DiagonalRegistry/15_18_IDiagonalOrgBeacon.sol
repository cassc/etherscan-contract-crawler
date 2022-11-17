// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title  IDiagonalOrgBeacon contract interface
 * @author Diagonal Finance
 */
interface IDiagonalOrgBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     */
    function implementation() external view returns (address);

    /**
     * @dev OrgBeacon owner.
     */
    function owner() external view returns (address);

    /**
     * @dev Update DiagonalOrg implementation.
     */
    function updateImplementation(address newImplementation) external;

    /**
     * @dev Update DiagonalBeacon owner.
     */
    function updateOwner(address newOwner) external;
}