// SPDX-License-Identifier:UNLICENSED
pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IWhitelist.sol";

/// @title AccessControlBasedWhitelist
///
/// @dev This contract is based in OpenZeppelin AccessControl that allows to implement role-based access

contract AccessControlBasedWhitelist is IWhitelist, AccessControl {
    // Create a new role identifier for the transfer role
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    constructor(address _trader) {
        require(_trader != address(0), "invalid address");
        // Grant the transfer role to a specified account
        _setupRole(TRANSFER_ROLE, _trader);
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @param _who the address that wants to transfer a NFT
     * @dev Returns true if address has permission to transfer a NFT
     */
    function canTransfer(address _who) external view override returns (bool) {
        return hasRole(TRANSFER_ROLE, _who);
    }
}