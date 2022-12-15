// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract Access is AccessControl {
    Mode public mode;

    enum Mode {
        OWNER,
        WHITELIST,
        PUBLIC
    }

    bytes32 internal constant ROLE_ADMIN        = bytes32("ROLE:ADMIN");
    bytes32 internal constant ROLE_OWNER        = bytes32("ROLE:OWNER");
    bytes32 internal constant ROLE_WHITELIST    = bytes32("ROLE:WHITELIST");
    bytes32 internal constant ROLE_PUBLIC       = bytes32("ROLE:PUBLIC");

    constructor (Mode mode_) public AccessControl() {
        mode = mode_;
        super._setRoleAdmin(ROLE_OWNER, ROLE_ADMIN);
        super._setRoleAdmin(ROLE_WHITELIST, ROLE_OWNER);
        super._setupRole(ROLE_ADMIN, _msgSender());
        super._setupRole(ROLE_OWNER, _msgSender());
        super._setupRole(ROLE_WHITELIST, _msgSender());
    }

    function changeMode(Mode mode_) external onlyOwner {
        mode = mode_;
    }

    function transferOwnership(address target) external onlyOwner {
        super._setupRole(ROLE_ADMIN, target);
        super._setupRole(ROLE_OWNER, target);
        super._setupRole(ROLE_WHITELIST, target);
        super.renounceRole(ROLE_WHITELIST, _msgSender());
        super.renounceRole(ROLE_OWNER, _msgSender());
        super.renounceRole(ROLE_ADMIN, _msgSender());
    }

    function grantRoleWhitelist(address target) external onlyOwner {
        super._setupRole(ROLE_WHITELIST, target);
    }

    function revokeRoleWhitelist(address target) external onlyOwner {
        super.revokeRole(ROLE_WHITELIST, target);
    }

    modifier onlyOwner() {
        require(hasRole(ROLE_OWNER, _msgSender()), "REQUIRE OWNER");
        _;
    }

    modifier checkRole() {
        if (mode == Mode.OWNER) {
            require(hasRole(ROLE_OWNER, _msgSender()), "REQUIRE OWNER");
        } else if (mode == Mode.WHITELIST) {
            require(hasRole(ROLE_WHITELIST, _msgSender()), "REQUIRE SENDER IN WHITELIST");
        }
        _;
    }
}