// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.11;

/**
    @title Interface for handler contracts that support deposits and deposit executions.
    @author ChainSafe Systems.
 */
interface IDepositExecute {
    /**
        @notice It is intended that deposit are made using the Bridge contract.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of token to be used for deposit.
        @param depositer Address of account making the deposit in the Bridge contract.
        @param data Consists of additional data needed for a specific deposit.
     */
    function deposit(uint8 destinationDomainID, bytes32 resourceID, address depositer, bytes calldata data) external returns (bytes memory);

    /**
        @notice It is intended that proposals are executed by the Bridge contract.
        @param destinationDomainID ID of chain deposit will be bridged to.
        @param resourceID ResourceID used to find address of token to be used for deposit.
        @param data Consists of additional data needed for a specific deposit execution.
     */
    function executeProposal(uint8 destinationDomainID, bytes32 resourceID, bytes calldata data) external;
}