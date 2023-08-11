// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

//  helper contracts
import { RegistryStorage } from "./RegistryStorage.sol";
import { ModifiersController } from "./ModifiersController.sol";

/**
 * @title RegistryProxy Contract
 * @author Opty.fi
 * @dev Storage for the Registry is at this address,
 * while execution is delegated to the `registryImplementation`.
 * Registry should reference this contract as their controller.
 * It defines a fallback function that delegates all calls to the address
 * returned by the abstract _implementation() internal function.
 */
contract RegistryProxy is RegistryStorage, ModifiersController {
    /**
     * @notice Emitted when pendingComptrollerImplementation is changed
     * @param oldPendingImplementation Old Registry contract's implementation address which is still pending
     * @param newPendingImplementation New Registry contract's implementation address which is still pending
     */
    event NewPendingImplementation(address oldPendingImplementation, address newPendingImplementation);

    /**
     * @notice Emitted when pendingComptrollerImplementation is updated
     * @param oldImplementation Old Registry Contract's implementation address
     * @param newImplementation New Registry Contract's implementation address
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Emitted when pendingGovernance is changed
     * @param oldPendingGovernance Old Governance's address which is still pending
     * @param newPendingGovernance New Governance's address which is still pending
     */
    event NewPendingGovernance(address oldPendingGovernance, address newPendingGovernance);

    /**
     * @notice Emitted when pendingGovernance is accepted, which means governance is updated
     * @param oldGovernance Old Governance's address
     * @param newGovernance New Governance's address
     */
    event NewGovernance(address oldGovernance, address newGovernance);

    constructor() public {
        governance = msg.sender;
        setFinanceOperator(msg.sender);
        setRiskOperator(msg.sender);
        setStrategyOperator(msg.sender);
        setOperator(msg.sender);
    }

    /* solhint-disable */
    receive() external payable {
        revert();
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev Returns to external caller whatever implementation returns or forwards reverts
     */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = registryImplementation.delegatecall(msg.data);

        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())

            switch success
                case 0 {
                    revert(free_mem_ptr, returndatasize())
                }
                default {
                    return(free_mem_ptr, returndatasize())
                }
        }
    }

    /* solhint-disable */

    /*** Admin Functions ***/
    /**
     * @dev Set the registry contract as pending implementation initally
     * @param newPendingImplementation registry address to act as pending implementation
     */
    function setPendingImplementation(address newPendingImplementation) external onlyOperator {
        address oldPendingImplementation = pendingRegistryImplementation;

        pendingRegistryImplementation = newPendingImplementation;

        emit NewPendingImplementation(oldPendingImplementation, pendingRegistryImplementation);
    }

    /**
     * @notice Accepts new implementation of registry
     * @dev Governance function for new implementation to accept it's role as implementation
     */
    function acceptImplementation() external returns (uint256) {
        // Check caller is pendingImplementation and pendingImplementation ≠ address(0)
        require(
            msg.sender == pendingRegistryImplementation && pendingRegistryImplementation != address(0),
            "!pendingRegistryImplementation"
        );

        // Save current values for inclusion in log
        address oldImplementation = registryImplementation;
        address oldPendingImplementation = pendingRegistryImplementation;

        registryImplementation = pendingRegistryImplementation;

        pendingRegistryImplementation = address(0);

        emit NewImplementation(oldImplementation, registryImplementation);
        emit NewPendingImplementation(oldPendingImplementation, pendingRegistryImplementation);

        return uint256(0);
    }

    /**
     * @notice Transfers the governance rights
     * @dev The newPendingGovernance must call acceptGovernance() to finalize the transfer
     * @param newPendingGovernance New pending governance address
     */
    function setPendingGovernance(address newPendingGovernance) external onlyOperator {
        // Save current value, if any, for inclusion in log
        address oldPendingGovernance = pendingGovernance;

        // Store pendingGovernance with value newPendingGovernance
        pendingGovernance = newPendingGovernance;

        // Emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance)
        emit NewPendingGovernance(oldPendingGovernance, newPendingGovernance);
    }

    /**
     * @notice Accepts transfer of Governance rights
     * @dev Governance function for pending governance to accept role and update Governance
     */
    function acceptGovernance() external returns (uint256) {
        require(msg.sender == pendingGovernance && msg.sender != address(0), "!pendingGovernance");

        // Save current values for inclusion in log
        address oldGovernance = governance;
        address oldPendingGovernance = pendingGovernance;

        // Store admin with value pendingGovernance
        governance = pendingGovernance;

        // Clear the pending value
        pendingGovernance = address(0);

        emit NewGovernance(oldGovernance, governance);
        emit NewPendingGovernance(oldPendingGovernance, pendingGovernance);
        return uint256(0);
    }
}