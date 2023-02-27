// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice The account registry manages mappings from an address to an account
/// ID.
interface IAccountRegistry {
    /// @notice Permissionlessly create a new account for the subject address.
    /// Subject must not yet have an account.
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id);

    /// @notice Get the account ID for an address. Will revert if the address
    /// does not have an account
    function resolveId(address subject) external view returns (uint64 id);

    /// @notice Attempt to get the account ID for an address, and return 0 if
    /// the account does not exist. This is generally not recommended, as the
    /// caller must be careful to handle the zero-case to avoid potential access
    /// control pitfalls or bugs.
    /// @dev Prefer `resolveId` if possible. If you must use this function,
    /// ensure the zero-case is handled correctly.
    function unsafeResolveId(address subject) external view returns (uint64 id);
}