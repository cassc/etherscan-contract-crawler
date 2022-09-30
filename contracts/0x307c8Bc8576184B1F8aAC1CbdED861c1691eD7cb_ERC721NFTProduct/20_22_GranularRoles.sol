// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

abstract contract GranularRoles is AccessControlUpgradeable {
    // Roles list
    // Admin role can have 2 addresses:
    // one address same as (_owner) which can be changed
    // one for NFTPort API access which can only be revoked
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    // Following roles can have multiple addresses, can be changed by admin or update contrac role
    bytes32 public constant MINT_ROLE = keccak256("MINT_ROLE");
    bytes32 public constant UPDATE_CONTRACT_ROLE =
        keccak256("UPDATE_CONTRACT_ROLE");
    bytes32 public constant UPDATE_TOKEN_ROLE = keccak256("UPDATE_TOKEN_ROLE");
    bytes32 public constant BURN_ROLE = keccak256("BURN_ROLE");
    bytes32 public constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");

    struct RolesAddresses {
        bytes32 role;
        address[] addresses;
        bool frozen;
    }

    address internal _owner;
    address internal _nftPort;

    mapping(bytes32 => address[]) internal _rolesAddressesIndexed; // Used to get roles enumeration
    mapping(bytes32 => bool) internal _rolesFrozen;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public {
        require(newOwner != _owner, "GranularRoles: already the owner");
        require(msg.sender == _owner, "GranularRoles: not the owner");
        _revokeRole(ADMIN_ROLE, _owner);
        address previousOwner = _owner;
        _owner = newOwner;
        _grantRole(ADMIN_ROLE, _owner);
        emit OwnershipTransferred(previousOwner, newOwner);
    }

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
        return
            super.hasRole(ADMIN_ROLE, account) || super.hasRole(role, account);
    }

    function _initRoles(address owner_, RolesAddresses[] memory rolesAddresses)
        internal
    {
        _owner = owner_;
        _nftPort = msg.sender;
        _grantRole(ADMIN_ROLE, _owner);
        _grantRole(ADMIN_ROLE, _nftPort);

        for (
            uint256 roleIndex = 0;
            roleIndex < rolesAddresses.length;
            roleIndex++
        ) {
            bytes32 role = rolesAddresses[roleIndex].role;
            require(
                _regularRoleValid(role),
                string(
                    abi.encodePacked(
                        "GranularRoles: invalid role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
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

    function _updateRoles(RolesAddresses[] memory rolesAddresses) internal {
        if (rolesAddresses.length > 0) {
            require(
                hasRole(ADMIN_ROLE, msg.sender),
                "GranularRoles: not an admin"
            );

            for (
                uint256 roleIndex = 0;
                roleIndex < rolesAddresses.length;
                roleIndex++
            ) {
                bytes32 role = rolesAddresses[roleIndex].role;
                require(
                    _regularRoleValid(role),
                    string(
                        abi.encodePacked(
                            "GranularRoles: invalid role ",
                            StringsUpgradeable.toHexString(uint256(role), 32)
                        )
                    )
                );
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

    function _regularRoleValid(bytes32 role) internal pure returns (bool) {
        return
            role == MINT_ROLE ||
            role == UPDATE_CONTRACT_ROLE ||
            role == UPDATE_TOKEN_ROLE ||
            role == BURN_ROLE ||
            role == TRANSFER_ROLE;
    }
}