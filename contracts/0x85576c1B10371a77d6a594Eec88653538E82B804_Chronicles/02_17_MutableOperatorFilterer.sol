// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";

/**
 * @title  MutableOperatorFilterer
 * @author shinji at shinji.xyz
 * @notice Allows the contract to change the registrant contract as well as the registrant address it listens to.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 *
 *         The contract will need to be registered with the registry once it is deployed in
 *         order for the modifier to filter addresses.
 */

contract MutableOperatorFilterer is Ownable {
    /// @dev Emitted when an operator is not allowed.
    error OperatorNotAllowed(address operator);

    // The contract with the filtering implementation
    address public OPERATOR_FILTER_REGISTRY_ADDRESS;

    // The agent the main contract listens to for filtering operators
    address public FILTER_REGISTRANT;

    IOperatorFilterRegistry public OPERATOR_FILTER_REGISTRY;

    constructor(
      address operatorFilterRegistryAddress,
      address operatorFilterRegistrant
    ) {
        OPERATOR_FILTER_REGISTRY_ADDRESS = operatorFilterRegistryAddress;
        OPERATOR_FILTER_REGISTRY = IOperatorFilterRegistry(OPERATOR_FILTER_REGISTRY_ADDRESS);
        FILTER_REGISTRANT =operatorFilterRegistrant;
    }

    /**
     * @notice Allows the owner to set a new registrant contract.
     */
    function setOperatorFilterRegistry(
        address registryAddress
    ) external onlyOwner {
        OPERATOR_FILTER_REGISTRY_ADDRESS = registryAddress;
        OPERATOR_FILTER_REGISTRY = IOperatorFilterRegistry(OPERATOR_FILTER_REGISTRY_ADDRESS);
    }

    /**
     * @notice Allows the owner to set a new registrant address.
     */
    function setFilterRegistrant(address newRegistrant) external onlyOwner {
        FILTER_REGISTRANT = newRegistrant;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    /**
     * @dev A helper function to check if an operator approval is allowed.
     */
    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    /**
     * @dev A helper function to check if an operator is allowed.
     */
    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            // under normal circumstances, this function will revert rather than return false, but inheriting contracts
            // may specify their own OperatorFilterRegistry implementations, which may behave differently
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(FILTER_REGISTRANT, operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}