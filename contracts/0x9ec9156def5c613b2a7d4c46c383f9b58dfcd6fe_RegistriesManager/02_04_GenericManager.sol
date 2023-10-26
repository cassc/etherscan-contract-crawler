// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/IErrorsRegistries.sol";

/// @title Generic Manager - Smart contract for generic registry manager template
/// @author Aleksandr Kuperman - <[email protected]>
abstract contract GenericManager is IErrorsRegistries {
    event OwnerUpdated(address indexed owner);
    event Pause(address indexed owner);
    event Unpause(address indexed owner);

    // Owner address
    address public owner;
    // Pause switch
    bool public paused;

    /// @dev Changes the owner address.
    /// @param newOwner Address of a new owner.
    function changeOwner(address newOwner) external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        // Check for the zero address
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }

        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /// @dev Pauses the contract.
    function pause() external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        paused = true;
        emit Pause(msg.sender);
    }

    /// @dev Unpauses the contract.
    function unpause() external virtual {
        // Check for the ownership
        if (msg.sender != owner) {
            revert OwnerOnly(msg.sender, owner);
        }

        paused = false;
        emit Unpause(msg.sender);
    }
}