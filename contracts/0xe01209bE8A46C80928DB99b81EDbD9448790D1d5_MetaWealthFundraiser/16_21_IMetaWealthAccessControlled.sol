/// SPDX-License-Identifier: None
pragma solidity ^0.8.7;

/// @title MetaWealth's internal minimal access control implementation
/// @dev This contract implements only two roles, Super Admin and an Admin
/// @dev Super admin is only responsible for changing admins
/// @dev Normal admins are checked for all of the access controls otherwise
/// @author Ghulam Haider
interface IMetaWealthAccessControlled {
    /// @notice Maintain event logs for every admin change calls
    /// @param changedBy is the wallet that called the change
    /// @param newAccount is the account that was granted admin access
    /// @param isSuper is a boolean representing whether the role was superAdmin or not
    event AdminChanged(address changedBy, address newAccount, bool isSuper);

    /// @notice Returns the current admin address
    /// @return bool if _account is admin
    function isAdmin(address _account) external view returns (bool);

    /// @notice Grants admin role access to a new account, revoking from previous
    /// @param newAccount is the new wallet address to grant admin role to
    function setAdmin(address newAccount) external;

    /// @notice Returns the current super admin address
    /// @return bool if _account is super admin
    function isSuperAdmin(address _account) external view returns (bool);

    /// @notice Grants super admin role access to a new account, revoking from previous
    /// @param newAccount is the new wallet address to grant super admin role to
    function setSuperAdmin(address newAccount) external;

    /// @notice Returns the current super admin address
    /// @return bool if _account is asset manager
    function isAssetManager(address _account) external view returns (bool);

    /// @notice Grants or revokes asset manager role access to a account depending on enabled
    /// @param _account _account to grant ot restrick aset managet role
    /// @param enabled grant or restrict
    function setAssetManager(address _account, bool enabled) external;
}