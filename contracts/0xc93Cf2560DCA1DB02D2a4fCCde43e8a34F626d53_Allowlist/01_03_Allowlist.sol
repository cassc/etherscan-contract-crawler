// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Maintains a list of addresses that can own Home onChain tokens.
/// @author Roofstock onChain team
contract Allowlist is Ownable {
    mapping(address => uint256) private allowed;
    event Allowed(address indexed account);
    event Disallowed(address indexed account);

    /// @notice Determines if an address exists in the allowlist.
    /// @param _address The address to check.
    /// @return Whether the address is allowed at this time.
    function isAllowed(address _address) public view returns(bool) {
        return allowed[_address] > block.timestamp;
    }

    /// @notice Gets the expiration date of the address in the allowlist.
    /// @param _address The address to check.
    /// @return The date that the address expires from the allowlist.
    function getExpiration(address _address) public view returns(uint256) {
        return allowed[_address];
    }

    /// @notice Add an address to the allowlist with an expiration date.
    /// @dev Only the owner can allow an address.
    /// @param _address The address to add to the allowlist.
    /// @param expiration The date for which the user will expire from the allowlist.
    function allow(address _address, uint256 expiration) public onlyOwner {
        allowed[_address] = expiration;
        emit Allowed(_address);
    }

    /// @notice Remove an address from the allowlist.
    /// @dev Only the owner can disallow an address.
    /// @dev It actually just automatically expires the user.
    /// @param _address The address to remove frome the allowlist.
    function disallow(address _address) public onlyOwner {
        allowed[_address] = block.timestamp;
        emit Disallowed(_address);
    }
}