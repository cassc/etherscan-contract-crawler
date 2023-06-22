/*
 * RollApp
 *
 * Copyright ©️ 2021 Curio AG (Company Number FL-0002.594.728-9)
 * Incorporated and registered in Liechtenstein.
 *
 * Copyright ©️ 2021 Curio Capital AG (Company Number CHE-211.446.654)
 * Incorporated and registered in Zug, Switzerland.
 */
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Adminable
 *
 * @dev Abstract contract provides a basic access control mechanism for Admin role.
 */
abstract contract Adminable is Ownable {
    // statuses of admins addresses
    mapping(address => bool) public admins;

    event AdminPermissionSet(address indexed account, bool isAdmin);

    /**
     * @dev Creates a contract with msg.sender as first admin.
     */
    constructor() internal {
        admins[msg.sender] = true;
    }

    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin {
        require(admins[msg.sender], "Adminable: permission denied");
        _;
    }

    modifier onlyOwnerOrAdmin {
        require(admins[msg.sender] || msg.sender == owner(), "Adminable: permission denied");
        _;
    }

    /**
     * @dev Allows the owner to add or remove other admin account.
     *
     * Requirements:
     * - can only be called by owner.
     *
     * @param _admin The address of admin account to add or remove.
     * @param _status True if admin is added, false if removed.
     */
    function setAdminPermission(address _admin, bool _status) public onlyOwner {
        _setAdminPermission(_admin, _status);
    }

    /**
     * @dev Allows the owner to add or remove many others admins.
     *
     * Requirements:
     * - can only be called by owner.
     * - the lengths of the arrays must be the same.
     *
     * @param _admins The array of addresses of admins accounts to add or remove.
     * @param _statuses Array of statuses of each address.
     */
    function setAdminPermissions(
        address[] memory _admins,
        bool[] memory _statuses
    ) public onlyOwner {
        uint256 len = _admins.length;
        require(len == _statuses.length, "Adminable: Array lengths do not match");

        for (uint256 i = 0; i < len; i++) {
            _setAdminPermission(_admins[i], _statuses[i]);
        }
    }

    /**
     * @dev Sets the admin/not admin status for the specified address.
     *
     * Emits a {AdminPermissionSet} event with `account` set to new added
     * or removed admin address and `isAdmin` set to admin account status.
     *
     * @param _admin The address of admin account to add or remove.
     * @param _status True if admin is added, false if removed.
     */
    function _setAdminPermission(address _admin, bool _status) internal {
        admins[_admin] = _status;
        emit AdminPermissionSet(_admin, _status);
    }
}