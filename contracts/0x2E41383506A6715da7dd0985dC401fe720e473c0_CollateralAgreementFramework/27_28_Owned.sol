// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice Simple single owner authorization mixin.
/// @dev Adapted from Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /// @notice Raised when the ownership is transferred.
    /// @param user Address of the user that transferred the ownerhip.
    /// @param newOwner Address of the new owner.
    event OwnershipTransferred(address indexed user, address indexed newOwner);

    error Unauthorized();

    /// @notice Address that owns the contract.
    address public owner;

    modifier onlyOwner() virtual {
        if (msg.sender != owner) revert Unauthorized();

        _;
    }

    constructor(address owner_) {
        owner = owner_;

        emit OwnershipTransferred(msg.sender, owner_);
    }

    /// @notice Transfer the ownership of the contract.
    /// @param newOwner Address of the new owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}