// SPDX-License-Identifier: GPLv2
pragma solidity ^0.8.1;

import "../interfaces/IPixelMushrohmAuthority.sol";

abstract contract PixelMushrohmAccessControlled {
    /* ========== EVENTS ========== */

    event AuthorityUpdated(IPixelMushrohmAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas
    string PAUSED = "PAUSED";
    string UNPAUSED = "UNPAUSED";

    /* ========== STATE VARIABLES ========== */

    IPixelMushrohmAuthority public authority;

    /* ========== Constructor ========== */

    constructor(IPixelMushrohmAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }

    /* ========== MODIFIERS ========== */

    modifier onlyOwner() {
        require(msg.sender == authority.owner(), UNAUTHORIZED);
        _;
    }

    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }

    modifier whenNotPaused() {
        require(!authority.paused(), PAUSED);
        _;
    }

    modifier whenPaused() {
        require(authority.paused(), UNPAUSED);
        _;
    }

    /* ========== OWNER ONLY ========== */

    function setAuthority(IPixelMushrohmAuthority _newAuthority) external onlyOwner {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}