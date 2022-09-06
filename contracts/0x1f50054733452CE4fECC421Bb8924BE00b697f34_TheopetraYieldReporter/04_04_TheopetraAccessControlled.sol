// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../Interfaces/ITheopetraAuthority.sol";

abstract contract TheopetraAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(ITheopetraAuthority indexed authority);

    string constant UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    ITheopetraAuthority public authority;

    /* ========== Constructor ========== */

    constructor(ITheopetraAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }

    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == authority.manager(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    /* ========== GOV ONLY ========== */

    function setAuthority(ITheopetraAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}