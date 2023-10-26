// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "../external/interfaces/IDelegationRegistry.sol";

import "./CallWhitelist.sol";

import { CWD_RegistryAlreadySet, CWD_ZeroAddress } from "../errors/Vault.sol";

/**
 * @title CallWhitelistDelegation
 * @author Non-Fungible Technologies, Inc.
 *
 * Adds delegation functionality to CallWhitelist, allowing the
 * whitelist manager to decide which collections can be used with
 * the DelegateCash registry. Each token should be considered for
 * possible implications of delegation before adding to the whitelist.
 *
 * If a token is on the whitelist, delegateForContract and delegateForToken
 * will be enabled for that token.
 *
 * WARNING: adding these functions to the core CallWhitelist whitelist will bypass
 * the delegation functions that check the whitelist for which tokens can
 * be delegated. The whitelist manager should take care not to use both the core
 * whitelist for delegation as well as the delegation whitelist.
 */
contract CallWhitelistDelegation is CallWhitelist {
    event DelegationSet(address indexed caller, address indexed token, bool isApproved);
    event RegistryChanged(address indexed caller, address indexed registry);

    // ============================================ STATE ==============================================

    // ================= Whitelist State ==================

    /// @notice Tokens approved for delegation.
    /// @dev    token -> isApproved
    mapping(address => bool) private delegationApproved;

    /// @notice The delegation registry for the whitelist.
    IDelegationRegistry public registry;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @dev Initializes values so initialize cannot be called on template.
     */
    constructor(address _registry) {
        if (_registry == address(0)) revert CWD_ZeroAddress();

        registry = IDelegationRegistry(_registry);
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Returns true if the given spender is approved to spend the given token.
     *
     * @param token                     The token approval to check.
     *
     * @return isDelegationApproved     True if the token can be delegated, else false.
     */
    function isDelegationApproved(address token) public view returns (bool) {
        return delegationApproved[token];
    }

    // ======================================== UPDATE OPERATIONS =======================================

    /**
     * @notice Sets approval status of a given token for a spender. Note that this is
     *         NOT a token approval - it is permission to register a delegation from
     *         the vault.
     *
     * @param token                The token approval to set.
     * @param _isApproved          Whether the token should be approved.
     */
    function setDelegationApproval(address token, bool _isApproved) external onlyRole(WHITELIST_MANAGER_ROLE) {
        delegationApproved[token] = _isApproved;

        emit DelegationSet(msg.sender, token, _isApproved);
    }

    /**
     * @notice Sets the registry for the whitelist. Should only be used in case
     *         of delegate cash migration to new registry.
     *
     * @param _registry             The new registry.
     */
    function setRegistry(address _registry) external onlyRole(ADMIN_ROLE) {
        if (address(registry) == _registry) revert CWD_RegistryAlreadySet();

        registry = IDelegationRegistry(_registry);

        emit RegistryChanged(msg.sender, _registry);
    }
}