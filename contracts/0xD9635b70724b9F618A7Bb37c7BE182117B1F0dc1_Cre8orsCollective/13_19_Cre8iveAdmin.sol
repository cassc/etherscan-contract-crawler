// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {AccessControl} from "lib/openzeppelin-contracts/contracts/access/AccessControl.sol";

/**
 ██████╗██████╗ ███████╗ █████╗  ██████╗ ██████╗ ███████╗
██╔════╝██╔══██╗██╔════╝██╔══██╗██╔═══██╗██╔══██╗██╔════╝
██║     ██████╔╝█████╗  ╚█████╔╝██║   ██║██████╔╝███████╗
██║     ██╔══██╗██╔══╝  ██╔══██╗██║   ██║██╔══██╗╚════██║
╚██████╗██║  ██║███████╗╚█████╔╝╚██████╔╝██║  ██║███████║
 ╚═════╝╚═╝  ╚═╝╚══════╝ ╚════╝  ╚═════╝ ╚═╝  ╚═╝╚══════╝                                                       
 */
/// @dev inspiration: https://etherscan.io/address/0x23581767a106ae21c074b2276d25e5c3e136a68b#code
contract Cre8iveAdmin is AccessControl {
    /// @notice Access control roles
    bytes32 public immutable MINTER_ROLE = keccak256("MINTER");
    bytes32 public immutable SALES_MANAGER_ROLE = keccak256("SALES_MANAGER");
    /// @notice Role of administrative users allowed to expel a CRE8OR from the Warehouse.
    /// @dev See expelFromWarehouse().
    bytes32 public constant EXPULSION_ROLE = keccak256("EXPULSION_ROLE");

    /// @notice Missing the given role or admin access
    error AdminAccess_MissingRoleOrAdmin(bytes32 role);

    constructor(address _initialOwner) {
        // Setup the owner role
        _setupRole(DEFAULT_ADMIN_ROLE, _initialOwner);
    }

    /////////////////////////////////////////////////
    /// MODIFIERS
    /////////////////////////////////////////////////

    /// @notice Only a given role has access or admin
    /// @param role role to check for alongside the admin role
    modifier onlyRoleOrAdmin(bytes32 role) {
        if (
            !hasRole(DEFAULT_ADMIN_ROLE, msg.sender) &&
            !hasRole(role, msg.sender)
        ) {
            revert AdminAccess_MissingRoleOrAdmin(role);
        }

        _;
    }
}