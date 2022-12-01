// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/*
 * Custom roles handling abstract contract.
 * Used for fine-grained access controls to contracts.
 * Supported roles are:
 * - `ADMIN_ROLE`, is granted to the initializer and one other account specified during intialization
 * - `MINT_ROLE`, is used for minting tokens
 * - `UPDATE_CONTRACT_ROLE`, is used for updating the contract
 * - `BURN_ROLE`, is used for burning tokens
 * - `TRANSFER_ROLE`, is used for transferring tokens
 * `ADMIN_ROLE` has all the access rights for all the roles.
 *
 * Each role besides the `ADMIN_ROLE` can have any amount of addresses and can be made immutable.
 */
abstract contract GranularRoles is AccessControlUpgradeable {
    // Roles list
    // Admin role can have 2 addresses:
    // one address same as (_owner) which can be changed
    // one for NFTPort API access which can only be revoked
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // Following roles can have multiple addresses, can be changed by admin or update contract role
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant UPDATE_CONTRACT_ROLE =
        keccak256("UPDATE_CONTRACT_ROLE");
    bytes32 public constant UPDATE_TOKEN_ROLE = keccak256("UPDATE_TOKEN_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    /*
     * Used for intializing and updating roles
     * Each role can have any number of addresses attached to it and can be frozen separately,
     * meaning any further updates to it are disabled.
     * Cannot be used to update or initialize `ADMIN_ROLE`.
     */
    struct RolesAddresses {
        bytes32 role;
        address[] addresses;
        bool frozen;
    }

    // Contract owner address, this address can edit the contract on OpenSea and has `ADMIN_ROLE`
    address internal _owner;
    // Initialized as the address that initializes the contract.
    address internal _nftPort;

    // Used to get roles enumeration
    mapping(bytes32 => address[]) internal _rolesAddressesIndexed;
    // Mapping from role to boolean that shows if role can be updated
    mapping(bytes32 => bool) internal _rolesFrozen;

    // Event emitted when `transferOwnership` called by current owner.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /*
     * Contract owner address
     * @dev Required for easy integration with OpenSea, the owner address can edit the collection there
     */
    function owner() public view returns (address) {
        return _owner;
    }

    // Transfer contract ownership, only callable by the current owner
    function transferOwnership(address newOwner) public {
        require(newOwner != _owner, "GranularRoles: already the owner");
        require(msg.sender == _owner, "GranularRoles: not the owner");
        _revokeRole(ADMIN_ROLE, _owner);
        address previousOwner = _owner;
        _owner = newOwner;
        _grantRole(ADMIN_ROLE, _owner);
        emit OwnershipTransferred(previousOwner, newOwner);
    }

    // Removes `ADMIN_ROLE` from the account that initialized the contract
    function revokeNFTPortPermissions() public onlyRole(ADMIN_ROLE) {
        _revokeRole(ADMIN_ROLE, _nftPort);
        _nftPort = address(0);
    }

    // Admin role has all access granted by default
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        // Contract owner has all access rights
        if (account == _owner) return true;
        // Anyone else cannot have DEFAULT_ADMIN_ROLE
        if (role == DEFAULT_ADMIN_ROLE) return false;
        // ADMIN_ROLE inherits any other roles
        return
            super.hasRole(ADMIN_ROLE, account) || super.hasRole(role, account);
    }

    /**
     * Initialize roles, should only be called once, for updating `_updateRoles` is used.
     * Can only be used to set the `_owner` and `_nftport` addresses,
     * or any amount of accounts for any supported role.
     */
    function _initRoles(address owner_, RolesAddresses[] memory rolesAddresses)
        internal
    {
        require(owner_ != address(0), "Contract must have an owner");
        _owner = owner_;
        _nftPort = msg.sender;
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(ADMIN_ROLE, _nftPort);

        // Loop through all roles from the input
        for (
            uint256 roleIndex = 0;
            roleIndex < rolesAddresses.length;
            roleIndex++
        ) {
            bytes32 role = rolesAddresses[roleIndex].role;
            // Check if the role is supported and is not `ADMIN_ROLE`
            require(
                _regularRoleValid(role),
                string(
                    abi.encodePacked(
                        "GranularRoles: invalid role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
            // Loop through all the addresses for the role being processed
            // Grant the given role to all the specified addresses
            // and add them to the roles enumaration `_rolesAddressesIndexed`
            for (
                uint256 addressIndex = 0;
                addressIndex < rolesAddresses[roleIndex].addresses.length;
                addressIndex++
            ) {
                _grantRole(
                    role,
                    rolesAddresses[roleIndex].addresses[addressIndex]
                );
                _rolesAddressesIndexed[role].push(
                    rolesAddresses[roleIndex].addresses[addressIndex]
                );
            }
            // If the given role is frozen then further updates to it are disabled
            if (rolesAddresses[roleIndex].frozen) {
                _rolesFrozen[role] = true;
            }
        }
    }

    /**
     * Used for updating and/or freezing roles.
     * Only callable by accounts with the `ADMIN_ROLE`
     * and cannot be used to update `ADMIN_ROLE`
     */
    function _updateRoles(RolesAddresses[] memory rolesAddresses) internal {
        if (rolesAddresses.length > 0) {
            require(
                hasRole(ADMIN_ROLE, msg.sender),
                "GranularRoles: not an admin"
            );

            // Loop through all roles from the input
            for (
                uint256 roleIndex = 0;
                roleIndex < rolesAddresses.length;
                roleIndex++
            ) {
                bytes32 role = rolesAddresses[roleIndex].role;
                // Check if the role is supported and is not `ADMIN_ROLE`
                require(
                    _regularRoleValid(role),
                    string(
                        abi.encodePacked(
                            "GranularRoles: invalid role ",
                            StringsUpgradeable.toHexString(uint256(role), 32)
                        )
                    )
                );
                // If given role is frozen then it cannot be updated
                require(
                    !_rolesFrozen[role],
                    string(
                        abi.encodePacked(
                            "GranularRoles: role ",
                            StringsUpgradeable.toHexString(uint256(role), 32),
                            " is frozen"
                        )
                    )
                );
                // Loop through all the addresses for the given role
                // Remove all accounts from the role being processed to add new ones from the input
                for (
                    uint256 addressIndex = 0;
                    addressIndex < _rolesAddressesIndexed[role].length;
                    addressIndex++
                ) {
                    _revokeRole(
                        role,
                        _rolesAddressesIndexed[role][addressIndex]
                    );
                }
                delete _rolesAddressesIndexed[role];
                // Loop through all the addresses for the given role from the input.
                // Grant roles to given addresses for the role being processed
                // and add the accounts to the role enumeration.
                for (
                    uint256 addressIndex = 0;
                    addressIndex < rolesAddresses[roleIndex].addresses.length;
                    addressIndex++
                ) {
                    _grantRole(
                        role,
                        rolesAddresses[roleIndex].addresses[addressIndex]
                    );
                    _rolesAddressesIndexed[role].push(
                        rolesAddresses[roleIndex].addresses[addressIndex]
                    );
                }
                if (rolesAddresses[roleIndex].frozen) {
                    _rolesFrozen[role] = true;
                }
            }
        }
    }

    // Checks if role is valid, does not contain the `ADMIN_ROLE`
    function _regularRoleValid(bytes32 role) internal pure returns (bool) {
        return
            role == MINT_ROLE ||
            role == UPDATE_CONTRACT_ROLE ||
            role == UPDATE_TOKEN_ROLE ||
            role == BURN_ROLE ||
            role == TRANSFER_ROLE;
    }
}