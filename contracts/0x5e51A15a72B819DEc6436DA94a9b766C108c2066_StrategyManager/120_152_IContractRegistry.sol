// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

/**
 * @title Interface for Contracts deployed with registry contract
 * @author Opty.fi
 * @notice Interface to get registry contract
 */
interface IContractRegistry {
    /**
     * @notice Get the address of registry contract
     * @return address of registry contract
     */
    function registryContract() external view returns (address);
}