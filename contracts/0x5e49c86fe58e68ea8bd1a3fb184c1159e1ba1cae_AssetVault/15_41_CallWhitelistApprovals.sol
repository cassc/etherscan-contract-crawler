// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.18;

import "./CallWhitelist.sol";

/**
 * @title CallWhitelistApprovals
 * @author Non-Fungible Technologies, Inc.
 *
 * Adds approvals functionality to CallWhitelist. Certain spenders
 * can be approved for tokens on vaults, with the requisite ability
 * to withdraw. Should not be used for tokens acting as collateral.
 *
 * The contract owner can add or remove approved token/spender pairs.
 */
contract CallWhitelistApprovals is CallWhitelist {
    event ApprovalSet(address indexed caller, address indexed token, address indexed spender, bool isApproved);

    // ============================================ STATE ==============================================

    // ================= Whitelist State ==================

    /// @notice Approved spenders of vault tokens.
    /// @dev    token -> spender -> isApproved
    mapping(address => mapping(address => bool)) private approvals;

    /**
     * @notice Returns true if the given spender is approved to spend the given token.
     *
     * @param token                The token approval to check.
     * @param spender              The token spender.
     *
     * @return isApproved          True if approved, else false.
     */
    function isApproved(address token, address spender) public view returns (bool) {
        return approvals[token][spender];
    }

    // ======================================== UPDATE OPERATIONS =======================================

    /**
     * @notice Sets approval status of a given token for a spender. Note that this is
     *         NOT a token approval - it is permission to create a token approval from
     *         the asset vault.
     *
     * @param token                The token approval to set.
     * @param spender              The token spender.
     * @param _isApproved          Whether the spender should be approved.
     */
    function setApproval(address token, address spender, bool _isApproved) external onlyRole(WHITELIST_MANAGER_ROLE) {
        approvals[token][spender] = _isApproved;
        emit ApprovalSet(msg.sender, token, spender, _isApproved);
    }
}