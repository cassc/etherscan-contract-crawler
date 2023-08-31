// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IOperatorFilterRegistry } from "operator-filter-registry/IOperatorFilterRegistry.sol";
import { AccessControl } from "openzeppelin/contracts/access/AccessControl.sol";
import { CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS } from "operator-filter-registry/lib/Constants.sol";

abstract contract RegistryManager is AccessControl {
    // ---------- Roles ----------
    bytes32 public constant REGISTRY_MANAGER_ROLE = keccak256("REGISTRY_MANAGER_ROLE");

    // ---------- Storage ----------

    /// @notice The address of the Operator Filter Registry
    IOperatorFilterRegistry internal constant REGISTRY =
        IOperatorFilterRegistry(CANONICAL_OPERATOR_FILTER_REGISTRY_ADDRESS);

    // ---------- Constructor ----------

    /**
     * @notice  Constructs the Registry Manager contract
     * @dev     Zero address check handled by inheritor
     * @param   _owner      The owner of the contract
     */
    constructor(address _owner) {
        _grantRole(REGISTRY_MANAGER_ROLE, _owner);
    }

    // ---------- Registry Functions ----------

    /**
     * @notice Registers an address with the registry
     */
    function register(address registrant) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.register(registrant);
    }

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.registerAndSubscribe(registrant, subscription);
    }

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(
        address registrant,
        address registrantToCopy
    ) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.registerAndCopyEntries(registrant, registrantToCopy);
    }

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.unregister(addr);
    }

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(
        address registrant,
        address operator,
        bool filtered
    ) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.updateOperator(registrant, operator, filtered);
    }

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(
        address registrant,
        address[] calldata operators,
        bool filtered
    ) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.updateOperators(registrant, operators, filtered);
    }

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(
        address registrant,
        bytes32 codehash,
        bool filtered
    ) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.updateCodeHash(registrant, codehash, filtered);
    }

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(
        address registrant,
        bytes32[] calldata codeHashes,
        bool filtered
    ) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.updateCodeHashes(registrant, codeHashes, filtered);
    }

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.subscribe(registrant, registrantToSubscribe);
    }

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external onlyRole(REGISTRY_MANAGER_ROLE) {
        REGISTRY.unsubscribe(registrant, copyExistingEntries);
    }
}