// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.15;

/**
 * @title  IOrganizationManagement contract interface
 * @author Diagonal Finance
 * @notice Organization module. Encapsulates organization management logic
 */
interface IOrganizationManagement {
    function updateSigner(address newSigner) external;
}