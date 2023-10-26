//SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.10;

/// @title Allowlist Interface (v1)
/// @author Kiln
/// @notice This interface exposes methods to handle the list of allowed recipients.
interface IAllowlistV1 {
    /// @notice The permissions of several accounts have changed
    /// @param accounts List of accounts
    /// @param permissions New permissions for each account at the same index
    event SetAllowlistPermissions(address[] accounts, uint256[] permissions);

    /// @notice The stored allower address has been changed
    /// @param allower The new allower address
    event SetAllower(address indexed allower);

    /// @notice The provided accounts list is empty
    error InvalidAlloweeCount();

    /// @notice The account is denied access
    /// @param _account The denied account
    error Denied(address _account);

    /// @notice The provided accounts and permissions list have different lengths
    error MismatchedAlloweeAndStatusCount();

    /// @notice Initializes the allowlist
    /// @param _admin Address of the Allowlist administrator
    /// @param _allower Address of the allower
    function initAllowlistV1(address _admin, address _allower) external;

    /// @notice Retrieves the allower address
    /// @return The address of the allower
    function getAllower() external view returns (address);

    /// @notice This method returns true if the user has the expected permission and
    ///         is not in the deny list
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    /// @return True if mask is respected and user is allowed
    function isAllowed(address _account, uint256 _mask) external view returns (bool);

    /// @notice This method returns true if the user is in the deny list
    /// @param _account Recipient to verify
    /// @return True if user is denied access
    function isDenied(address _account) external view returns (bool);

    /// @notice This method returns true if the user has the expected permission
    ///         ignoring any deny list membership
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    /// @return True if mask is respected
    function hasPermission(address _account, uint256 _mask) external view returns (bool);

    /// @notice This method retrieves the raw permission value
    /// @param _account Recipient to verify
    /// @return The raw permissions value of the account
    function getPermissions(address _account) external view returns (uint256);

    /// @notice This method should be used as a modifier and is expected to revert
    ///         if the user hasn't got the required permission or if the user is
    ///         in the deny list.
    /// @param _account Recipient to verify
    /// @param _mask Combination of permissions to verify
    function onlyAllowed(address _account, uint256 _mask) external view;

    /// @notice Changes the allower address
    /// @param _newAllowerAddress New address allowed to edit the allowlist
    function setAllower(address _newAllowerAddress) external;

    /// @notice Sets the allowlisting status for one or more accounts
    /// @dev The permission value is overridden and not updated
    /// @param _accounts Accounts with statuses to edit
    /// @param _permissions Allowlist permissions for each account, in the same order as _accounts
    function allow(address[] calldata _accounts, uint256[] calldata _permissions) external;
}