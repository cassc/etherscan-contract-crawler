// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

interface IOwnableAdmin {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Returns the admin of the contract.
    function admin() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setAdmin(address _newAdmin) external;

    /// @dev Emitted when a new Owner is set.
    event OwnerUpdated(address indexed prevOwner, address indexed newOwner);

    /// @dev Emitted when a new Admin is set.
    event AdminUpdated(address indexed prevAdmin, address indexed newAdmin);
}