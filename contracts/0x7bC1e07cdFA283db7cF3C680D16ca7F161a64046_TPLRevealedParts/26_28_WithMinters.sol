// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/// @title WithMinters
/// @author dev by @dievardump
/// @notice This contract adds minters management
abstract contract WithMinters {
    error OnlyMinter();

    /// @notice the address of the minter module
    mapping(address => bool) public minters;

    modifier onlyMinter() virtual {
        if (!minters[msg.sender]) {
            revert OnlyMinter();
        }
        _;
    }

    /// @notice Allows to add minters to this contract
    /// @param newMinters the new minters to add
    function _addMinters(address[] memory newMinters) internal virtual {
        uint256 length = newMinters.length;
        for (uint256 i; i < length; i++) {
            minters[newMinters[i]] = true;
        }
    }

    /// @notice Allows to remove minters from this contract
    /// @param oldMinters the old minters to remove
    function _removeMinters(address[] memory oldMinters) internal virtual {
        uint256 length = oldMinters.length;
        for (uint256 i; i < length; i++) {
            minters[oldMinters[i]] = false;
        }
    }
}