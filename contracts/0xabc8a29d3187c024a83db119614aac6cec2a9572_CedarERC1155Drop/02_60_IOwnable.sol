// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8;

interface IOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IPublicOwnable {
    /// @dev Returns the owner of the contract.
    function owner() external view returns (address);

    /// @dev Emitted when a new Owner is set.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IRestrictedOwnable {
    /// @dev Lets a module admin set a new owner for the contract. The new owner must be a module admin.
    function setOwner(address _newOwner) external;

    /// @dev Emitted when a new Owner is set.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}