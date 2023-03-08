// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.17;
// OZ imports
import "../../openzeppelin-contracts-upgradeable/contracts/access/AccessControlUpgradeable.sol";
import "../../openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../../openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @title Manage the Access Control
abstract contract AccessControlModule is
    AccessControlUpgradeable,
    OwnableUpgradeable
{
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    function __AuthorizationModule_init(address admin)
        internal
        onlyInitializing
    {
        /* OpenZeppelin */
        __Context_init_unchained();
        // AccessControlUpgradeable inherits from ERC165Upgradeable
        __ERC165_init_unchained();
        __AccessControl_init_unchained();

        /* own function */
        __AuthorizationModule_init_unchained(admin);
    }

    /**
     * @dev Grants the different roles to the admin
     * @param admin address
     *
     */
    function __AuthorizationModule_init_unchained(address admin)
        internal
        onlyInitializing
    {
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _transferOwnership(admin);

        grantOtherRoleToAdmin(admin);
    }

    /**
    @dev You can override this function if you do not want automatically 
    grand the admin with the different roles
     */
    function grantOtherRoleToAdmin(address admin) internal virtual {
        _grantRole(MINTER_ROLE, admin);
    }

    /*
    @notice Transfers the control of the contract from one address to another
    The transfer concerns the ownership and the adminiship of the contracts.
    The newAdmin (& new owner) will have the same roles as the current admin.
    Warning: make sure the address of newAdmin is correct.
    By transfering his rights, the former admin loses them all.
    @param newAdmin address of the new admin
    */
    function transferContractControl(address newAdmin) public onlyOwner {
        require(newAdmin != address(0), "Address 0 not allowed");
        address sender = _msgSender();
        require(sender != newAdmin, "Same address");
        transferOwnership(newAdmin);
        if (hasRole(MINTER_ROLE, sender)) {
            grantRole(MINTER_ROLE, newAdmin);
            renounceRole(MINTER_ROLE, sender);
        }
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, sender);
    }

    uint256[50] private __gap;
}