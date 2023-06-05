// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "hardhat/console.sol";

abstract contract BasicAccessController is AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant EXECUTIVE_ROLE = keccak256("EXECUTIVE_ROLE");
    bytes32 public constant EXECUTIVE_ROLE_2 = keccak256("EXECUTIVE_ROLE_2");

    bytes32 public constant ZAPPER_ROLE = keccak256("ZAPPER_ROLE");

    address private _addressExecutive;
    address private _addressExecutive2;
    address private _addressZapper;

    address private _nominatedAdmin;
    address private _oldAdmin;

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not Admin");
        _;
    }

    modifier onlyExecutive() {
        require(hasRole(EXECUTIVE_ROLE, msg.sender), "Caller is not Executive");
        _;
    }

    modifier onlyExecutive2() {
        require(
            hasRole(EXECUTIVE_ROLE_2, msg.sender),
            "Caller is not Executive2"
        );
        _;
    }

    modifier onlyAdminOrZapperOrExec() {
        require(
            hasRole(ADMIN_ROLE, msg.sender) ||
                hasRole(ZAPPER_ROLE, msg.sender) ||
                hasRole(EXECUTIVE_ROLE, msg.sender),
            "Caller is not Admin or Self"
        );
        _;
    }

    function setAdmin(address newAdmin) public onlyAdmin {
        if (newAdmin == _msgSender()) {
            revert("new admin must be different");
        }
        _nominatedAdmin = newAdmin;
        _oldAdmin = _msgSender();
    }

    function acceptAdminRole() external {
        if (_nominatedAdmin == address(0) || _oldAdmin == address(0)) {
            revert("no nominated admin");
        }
        if (_nominatedAdmin == _msgSender()) {
            _grantRole(ADMIN_ROLE, _msgSender());
            _revokeRole(ADMIN_ROLE, _oldAdmin);

            _nominatedAdmin = address(0);
            _oldAdmin = address(0);
        }
    }

    function renounceRole(
        bytes32 role,
        address account
    ) public virtual override {
        if (hasRole(ADMIN_ROLE, msg.sender)) {
            revert("Admin cant use renounceRole");
        }
        require(account == _msgSender(), "can only renounce roles for self");

        _revokeRole(role, account);
    }

    function setExecutive(address newExecutive) public onlyAdmin {
        address oldExecutive = _addressExecutive;
        require(
            oldExecutive != newExecutive,
            "New Executive must be different"
        );
        _grantRole(EXECUTIVE_ROLE, newExecutive);
        _revokeRole(EXECUTIVE_ROLE, oldExecutive);
        _addressExecutive = newExecutive;
    }

    function setExecutive2(address newExecutive2) public onlyAdmin {
        address oldExecutive2 = _addressExecutive2;
        require(
            oldExecutive2 != newExecutive2,
            "New Executive2 must be different"
        );
        _grantRole(EXECUTIVE_ROLE_2, newExecutive2);
        _revokeRole(EXECUTIVE_ROLE_2, oldExecutive2);
        _addressExecutive = newExecutive2;
    }

    function setZapper(address newZapper) public onlyAdmin {
        address oldZapper = _addressZapper;
        require(oldZapper != newZapper, "New Zapper must be different");
        _grantRole(EXECUTIVE_ROLE, newZapper);
        _revokeRole(EXECUTIVE_ROLE, oldZapper);
        _addressExecutive = newZapper;
    }

    function getAddressExecutive() public view returns (address) {
        return _addressExecutive;
    }

    function getAddressExecutive2() public view returns (address) {
        return _addressExecutive2;
    }

    function getAddressZapper() public view returns (address) {
        return _addressZapper;
    }

    function _requireAdmin() internal view {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not admin");
    }
}