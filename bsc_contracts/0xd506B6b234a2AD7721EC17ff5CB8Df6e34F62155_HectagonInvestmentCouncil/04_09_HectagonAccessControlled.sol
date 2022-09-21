// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../interfaces/IHectagonAuthority.sol";

error UNAUTHORIZED();

/**
 *   @dev Reasoning for this contract = modifiers literaly copy code
 *   instead of pointing towards the logic to execute. Over many
 *   functions this bloats contract size unnecessarily.
 */
abstract contract HectagonAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IHectagonAuthority authority);

    /* ========== STATE VARIABLES ========== */

    IHectagonAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IHectagonAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== "MODIFIERS" ========== */

    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    modifier onlyGuardian() {
        _onlyGuardian();
        _;
    }

    modifier onlyPolicy() {
        _onlyPolicy();
        _;
    }

    modifier onlyVault() {
        _onlyVault();
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(IHectagonAuthority _newAuthority) external {
        _onlyGovernor();
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }

    /* ========== INTERNAL CHECKS ========== */

    function _onlyGovernor() internal view {
        if (msg.sender != authority.governor()) revert UNAUTHORIZED();
    }

    function _onlyGuardian() internal view {
        if (msg.sender != authority.guardian()) revert UNAUTHORIZED();
    }

    function _onlyPolicy() internal view {
        if (msg.sender != authority.policy()) revert UNAUTHORIZED();
    }

    function _onlyVault() internal view {
        if (msg.sender != authority.vault()) revert UNAUTHORIZED();
    }
}