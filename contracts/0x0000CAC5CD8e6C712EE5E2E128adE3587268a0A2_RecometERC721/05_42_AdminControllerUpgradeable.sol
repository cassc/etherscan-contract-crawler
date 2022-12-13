// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

/**
 * @title AdminControllerUpgradeable
 * AdminControllerUpgradeable - This contract manages the admin.
 */
abstract contract AdminControllerUpgradeable is
    ContextUpgradeable,
    OwnableUpgradeable
{
    mapping(address => bool) private _admins;

    event AdminSet(address indexed account, bool indexed status);

    modifier onlyAdmin() {
        address sender = _msgSender();
        (bool isValid, string memory errorMessage) = _validateAdmin(sender);
        require(isValid, errorMessage);
        _;
    }

    modifier onlyAdminOrOwner() {
        address sender = _msgSender();
        (bool isValid, string memory errorMessage) = _validateAdminOrOwner(
            sender
        );
        require(isValid, errorMessage);
        _;
    }

    function __AdminController_init_unchained(address account) internal {
        _setAdmin(account, true);
    }

    function addAdmin(address account) external onlyOwner {
        _setAdmin(account, true);
    }

    function removeAdmin(address account) external onlyAdminOrOwner {
        _setAdmin(account, false);
    }

    function isAdmin(address account) external view returns (bool) {
        return _isAdmin(account);
    }

    function _setAdmin(address account, bool status) internal {
        _admins[account] = status;
        emit AdminSet(account, status);
    }

    function _isAdmin(address account) internal view returns (bool) {
        return _admins[account];
    }

    function _isAdminOrOwner(address account) internal view returns (bool) {
        return owner() == account || _isAdmin(account);
    }

    function _validateAdmin(address account)
        internal
        view
        returns (bool, string memory)
    {
        if (!_isAdmin(account)) {
            return (
                false,
                "AdminControllerUpgradeable: admin verification failed"
            );
        }
        return (true, "");
    }

    function _validateAdminOrOwner(address account)
        internal
        view
        returns (bool, string memory)
    {
        if (!_isAdminOrOwner(account)) {
            return (
                false,
                "AdminControllerUpgradeable: admin or owner verification failed"
            );
        }
        return (true, "");
    }

    uint256[50] private __gap;
}