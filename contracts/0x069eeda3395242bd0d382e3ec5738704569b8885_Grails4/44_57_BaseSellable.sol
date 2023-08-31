// SPDX-License-Identifier: MIT
// Copyright 2023 PROOF Holdings Inc
pragma solidity >=0.8.0 <0.9.0;

import {AccessControlEnumerable} from "ethier/utils/AccessControlEnumerable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {ISellable} from "../interfaces/ISellable.sol";

/**
 * @notice A base contract for selling content via authorised sellers.
 */
abstract contract BaseSellable is ISellable, AccessControlEnumerable, ReentrancyGuard {
    /**
     * @notice Authorised sellers.
     */
    bytes32 public constant AUTHORISED_SELLER_ROLE = keccak256("AUTHORISED_SELLER_ROLE");

    /**
     * @notice A role that cannot be granted or revoked.
     * @dev Used to lock in members of the `AUTHORISED_SELLER_ROLE` role.
     */
    bytes32 private constant _NOOP_ROLE = keccak256("NOOP_ROLE");

    constructor() {
        _setRoleAdmin(AUTHORISED_SELLER_ROLE, DEFAULT_STEERING_ROLE);
        _setRoleAdmin(_NOOP_ROLE, _NOOP_ROLE);
    }

    /**
     * @notice Handles the sale of sellable content via an authorised seller.
     * @dev Delegates the implementation to `_handleSale`.
     */
    function handleSale(address to, uint64 num, bytes calldata data)
        external
        payable
        onlyRole(AUTHORISED_SELLER_ROLE)
        nonReentrant
    {
        _handleSale(to, num, data);
    }

    /**
     * @notice Handles the sale of sellable content.
     */
    function _handleSale(address to, uint64 num, bytes calldata data) internal virtual;

    /**
     * @notice Locks the `AUTHORISED_SELLER_ROLE` role.
     */
    function lockSellers() external onlyRole(DEFAULT_STEERING_ROLE) {
        _lockSellers();
    }

    /**
     * @notice Locks the `AUTHORISED_SELLER_ROLE` role.
     */
    function _lockSellers() internal {
        _setRoleAdmin(AUTHORISED_SELLER_ROLE, _NOOP_ROLE);
    }

    /**
     * @notice Revokes approval for all sellers.
     */
    function _revokeAllSellers() internal {
        uint256 num = getRoleMemberCount(AUTHORISED_SELLER_ROLE);
        for (uint256 i = 0; i < num; i++) {
            // Akin to a popFront
            address seller = getRoleMember(AUTHORISED_SELLER_ROLE, 0);
            _revokeRole(AUTHORISED_SELLER_ROLE, seller);
        }
    }
}