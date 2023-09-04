// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ITorAddressRegister {
    /// @notice Thrown if provided index out of bounds.
    /// @param index The provided index.
    /// @param maxIndex The maximum valid index.
    error IndexOutOfBounds(uint index, uint maxIndex);

    /// @notice Emitted when new tor address added.
    /// @param caller The caller's address.
    /// @param torAddress The tor addresses added.
    event TorAddressAdded(address indexed caller, string torAddress);

    /// @notice Emitted when tor address removed.
    /// @param caller The caller's address.
    /// @param torAddress The tor addresses removed..
    event TorAddressRemoved(address indexed caller, string torAddress);

    /// @notice Returns the tor address at index `index`.
    /// @dev Reverts if index out of bounds.
    /// @param index The index of the tor address to return.
    /// @return The tor address stored at given index.
    function get(uint index) external view returns (string memory);

    /// @notice Returns the tor address at index `index`.
    /// @param index The index of the tor address to return.
    /// @return True if tor address at index `index` exists, false otherwise.
    /// @return The tor address stored at index `index` if index exists, empty
    ///         string otherwise.
    function tryGet(uint index) external view returns (bool, string memory);

    /// @notice Returns the full list of tor addresses stored.
    /// @dev May contain duplicates.
    /// @dev Stable ordering not guaranteed.
    /// @dev May contain the empty string or other invalid tor addresses.
    /// @return The list of tor addresses stored.
    function list() external view returns (string[] memory);

    /// @notice Returns the number of tor addresses stored.
    /// @return The number of tor addresses stored.
    function count() external view returns (uint);

    /// @notice Adds a new tor address.
    /// @dev Only callable by auth'ed addresses.
    /// @param torAddress The tor address to add.
    function add(string calldata torAddress) external;

    /// @notice Adds a list of new tor addresses.
    /// @dev Only callable by auth'ed addresses.
    /// @param torAddresses The tor addresses to add.
    function add(string[] calldata torAddresses) external;

    /// @notice Removes the tor address at index `index`.
    /// @dev Only callable by auth'ed addresses.
    /// @dev Reverts if index `index` out of bounds.
    /// @param index The index of the the tor address to remove.
    function remove(uint index) external;
}