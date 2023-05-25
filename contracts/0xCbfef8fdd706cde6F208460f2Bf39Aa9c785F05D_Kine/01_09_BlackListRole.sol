pragma solidity ^0.5.16;

import "./BlacklistAdminRole.sol";
import "./Context.sol";
import "./Roles.sol";

/**
 * @title BlackListRole
 */
contract BlackListRole is BlacklistAdminRole {
    using Roles for Roles.Role;

    /// @notice Emitted when blacklist admin add account into blacklist
    event BlacklistedAdded(address indexed account);
    /// @notice Emitted when blacklist admin remove account into blacklist
    event BlacklistedRemoved(address indexed account);

    /// @dev Blacklist is maintained by blacklist admins
    Roles.Role private _blacklisteds;

    /// @notice Prevent blacklisted account
    modifier onlyNotBlacklisted(address account) {
        require(!isBlacklisted(account), "BlacklistedRole: account is Blacklisted");
        _;
    }
    
    /** 
     * @notice Check if given account is in blacklist
     * @return True if account is in blacklist, and false if not in blacklist
     */
    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisteds.has(account);
    }

    /// @notice Add account into blacklist, only blacklist admin can do this
    function addBlacklisted(address account) public onlyBlacklistAdmin {
        _addBlacklisted(account);
    }

    /// @notice Remove account into blacklist, only blacklist admin can do this
    function removeBlacklisted(address account) public onlyBlacklistAdmin {
        _removeBlacklisted(account);
    }

    function _addBlacklisted(address account) internal {
        _blacklisteds.add(account);
        emit BlacklistedAdded(account);
    }

    function _removeBlacklisted(address account) internal {
        _blacklisteds.remove(account);
        emit BlacklistedRemoved(account);
    }
}