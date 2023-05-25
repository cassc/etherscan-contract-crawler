pragma solidity ^0.5.16;

import "./Context.sol";
import "./Roles.sol";

/**
 * @title BlacklistAdminRole
 */
contract BlacklistAdminRole is Context {
    using Roles for Roles.Role;

    /// @notice Emitted when new black list admin is added by existing admin
    event BlacklistAdminAdded(address indexed account);
    /// @notice Emitted when black list admin is removed by existing admin
    event BlacklistAdminRemoved(address indexed account);

    /// @dev Blacklist admins are responsible to maintain admin members
    Roles.Role private _blacklistAdmins;

    constructor () internal {
        _addBlacklistAdmin(_msgSender());
    }

    /// @notice Prevent non blacklist admin user from managing admin members
    modifier onlyBlacklistAdmin() {
        require(isBlacklistAdmin(_msgSender()), "BlacklistAdminRole: caller does not have the BlacklistAdmin role");
        _;
    }

    /// @notice Check if an account is blacklist admin member
    function isBlacklistAdmin(address account) public view returns (bool) {
        return _blacklistAdmins.has(account);
    }

    /// @notice Let caller to remove itself from blacklist admin members
    function renounceBlacklistAdmin() public {
        _removeBlacklistAdmin(_msgSender());
    }

    function _addBlacklistAdmin(address account) internal {
        _blacklistAdmins.add(account);
        emit BlacklistAdminAdded(account);
    }

    function _removeBlacklistAdmin(address account) internal {
        _blacklistAdmins.remove(account);
        emit BlacklistAdminRemoved(account);
    }
}