// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

import "../interfaces/ICallWhitelist.sol";

import "./CallBlacklist.sol";

import {
    CW_AlreadyWhitelisted,
    CW_NotWhitelisted
} from "../errors/Vault.sol";

/**
 * @title CallWhitelist
 * @author Non-Fungible Technologies, Inc.
 *
 * Maintains a whitelist for calls that can be made from an AssetVault.
 * Intended to be used to allow for "claim" and other-utility based
 * functions while an asset is being held in escrow. Some functions
 * are blacklisted, e.g. transfer functions, to prevent callers from
 * being able to circumvent withdrawal rules for escrowed assets.
 * Whitelists are specified in terms of "target contract" (callee)
 * and function selector.
 *
 * The contract owner can add or remove items from the whitelist.
 */
contract CallWhitelist is AccessControlEnumerable, CallBlacklist, ICallWhitelist {
    using SafeERC20 for IERC20;

    // ============================================ STATE ==============================================

    // =================== Constants =====================

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");
    bytes32 public constant WHITELIST_MANAGER_ROLE = keccak256("WHITELIST_MANAGER");

    // ================= Whitelist State ==================

    /**
     * @notice Whitelist of callable functions on contracts. Maps addresses that
     *         can be called to function selectors which can be called on it.
     *         For example, if we want to allow function call 0x0000 on a contract
     *         at 0x1111, the mapping will contain whitelist[0x1111][0x0000] = true.
     */
    mapping(address => mapping(bytes4 => bool)) private whitelist;

    // ========================================= CONSTRUCTOR ===========================================

    /**
     * @notice Creates a new call whitelist contract, setting up required roles.
     */
    constructor() {
        _setupRole(ADMIN_ROLE, msg.sender);

        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(WHITELIST_MANAGER_ROLE, ADMIN_ROLE);
    }

    // ========================================= VIEW FUNCTIONS =========================================

    /**
     * @notice Returns true if the given function on the given callee is whitelisted.
     *
     * @param callee                The contract that is intended to be called.
     * @param selector              The function selector that is intended to be called.
     *
     * @return isWhitelisted        True if whitelisted, else false.
     */
    function isWhitelisted(address callee, bytes4 selector) external view override returns (bool) {
        return !isBlacklisted(selector) && whitelist[callee][selector];
    }

    // ======================================== UPDATE OPERATIONS =======================================

    /**
     * @notice Add the given callee and selector to the whitelist. Can only be called by owner.
     *
     * @dev    A blacklist supersedes a whitelist, so should not add blacklisted selectors.
     *         Calls which are already whitelisted will revert.
     *
     * @param callee                The contract to whitelist.
     * @param selector              The function selector to whitelist.
     */
    function add(address callee, bytes4 selector) external override onlyRole(WHITELIST_MANAGER_ROLE) {
        mapping(bytes4 => bool) storage calleeWhitelist = whitelist[callee];

        if (calleeWhitelist[selector]) revert CW_AlreadyWhitelisted(callee, selector);
        calleeWhitelist[selector] = true;

        emit CallAdded(msg.sender, callee, selector);
    }

    /**
     * @notice Remove the given callee and selector from the whitelist. Can only be called by owner.
     *
     * @dev   Calls which are not already whitelisted will revert.
     *
     * @param callee                The contract to whitelist.
     * @param selector              The function selector to whitelist.
     */
    function remove(address callee, bytes4 selector) external override onlyRole(WHITELIST_MANAGER_ROLE) {
        mapping(bytes4 => bool) storage calleeWhitelist = whitelist[callee];

        if (!calleeWhitelist[selector]) revert CW_NotWhitelisted(callee, selector);
        calleeWhitelist[selector] = false;

        emit CallRemoved(msg.sender, callee, selector);
    }
}