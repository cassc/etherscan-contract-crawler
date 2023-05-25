// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract LaCollectionAccess is Ownable, AccessControl {
    bytes32 public constant LACOLLECTION_ROLE = keccak256("LACOLLECTION_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    modifier onlyLaCollection {
        require(
            hasRole(LACOLLECTION_ROLE, _msgSender()),
            "LaCollection: Caller has not LaCollectionRole"
        );
        _;
    }

    modifier onlyMinter {
        require(
            hasRole(MINTER_ROLE, _msgSender()) ||
                hasRole(LACOLLECTION_ROLE, _msgSender()),
            "LaCollection: Caller is not a minter"
        );
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(LACOLLECTION_ROLE, _msgSender());
    }

    function addLaCollectionRole(address account) external {
        grantRole(LACOLLECTION_ROLE, account);
    }

    function renounceLaCollectionRole(address account) external {
        renounceRole(LACOLLECTION_ROLE, account);
    }

    function revokeLaCollectionRole(address account) external {
        revokeRole(LACOLLECTION_ROLE, account);
    }

    function addMinterRole(address account) external {
        grantRole(MINTER_ROLE, account);
    }

    function renounceMinterRole(address account) external {
        renounceRole(MINTER_ROLE, account);
    }

    function revokeMinterRole(address account) external {
        revokeRole(MINTER_ROLE, account);
    }
}