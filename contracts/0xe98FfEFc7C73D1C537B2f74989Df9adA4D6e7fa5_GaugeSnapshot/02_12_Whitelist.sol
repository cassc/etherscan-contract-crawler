//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @title Whitelist
/// @author witherblock (modified by despereaux)
/// @notice A helper contract that lets you add a list of whitelisted addresses that should be able to interact with restricted functions
abstract contract Whitelist {
    /// @dev address => whitelisted or not
    mapping(address => bool) public whitelistedAddresses;

    /*==== SETTERS ====*/

    /// @dev add to the whitelist
    /// @param _address the address to add to the contract whitelist
    function _addToWhitelist(address _address) internal {
        whitelistedAddresses[_address] = true;

        emit AddToWhitelist(_address);
    }

    /// @dev remove from  the whitelist
    /// @param _address the address to remove from the contract whitelist
    function _removeFromWhitelist(address _address) internal {
        whitelistedAddresses[_address] = false;

        emit RemoveFromWhitelist(_address);
    }

    // modifier is eligible sender modifier
    function _isEligibleSender() internal view {
        require(whitelistedAddresses[tx.origin], "Address must be whitelisted");
    }

    /*==== EVENTS ====*/

    event AddToWhitelist(address indexed _address);

    event RemoveFromWhitelist(address indexed _address);
}