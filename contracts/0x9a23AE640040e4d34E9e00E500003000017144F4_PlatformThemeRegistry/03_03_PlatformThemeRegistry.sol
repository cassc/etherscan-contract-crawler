// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {Ownable} from "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/// @title PlatformThemeRegistry
/// @author Max Bochman
/// @notice Modified from: Zora Labs JSON Extension Registry v1
contract PlatformThemeRegistry is Ownable {
    //////////////////////////////
    /// ENUMS + TYPES
    //////////////////////////////

    /// @notice Access control roles
    /// NO_ROLE = 0, MANAGER = 1, ADMIN = 2
    enum Roles {
        NO_ROLE,
        MANAGER,
        ADMIN
    }

    struct RoleDetails {
        address account;
        Roles role;
    }

    //////////////////////////////
    /// STORAGE
    //////////////////////////////

    /// @notice Contract version
    uint256 public constant version = 1;

    // Stores link to initial documentation for this contract
    string internal _contractDocumentation = "https://docs.public---assembly.com/";

    // Stores platform counter
    uint256 public platformCounter = 0;

    // Platform index to string
    mapping(uint256 => string) platformThemeInfo;

    // Platform index to account to role
    mapping(uint256 => mapping(address => Roles)) roleInfo;

    //////////////////////////////
    /// ERRORS
    //////////////////////////////

    error RequiresAdmin();
    error RequiresHigherRole();
    error RoleDoesntExist();

    //////////////////////////////
    /// EVENTS
    //////////////////////////////

    event PlatformThemeUpdated(uint256 indexed platformIndex, address sender, string newTheme);

    event RoleGranted(uint256 indexed platformIndex, address sender, address account, Roles role);

    event RoleRevoked(uint256 indexed platformIndex, address sender, address account, Roles role);

    //////////////////////////////
    /// CONTRACT INFO
    //////////////////////////////

    /// @notice Contract name getter
    /// @dev Used to identify contract
    /// @return string contract name
    function name() external pure returns (string memory) {
        return "PlatformThemeRegistry";
    }

    /// @notice Contract documentation getter
    /// @dev Used to provide contract documentation
    /// @return string contract documentation uri
    function contractDocumentation() external view returns (string memory) {
        return _contractDocumentation;
    }

    /// @notice Update contract documentation in storage
    /// @dev Used to update contract documentation
    /// @return string contract documentation uri
    function setContractDocumentation(string memory newContractDocs) external onlyOwner returns (string memory) {
        _contractDocumentation = newContractDocs;
        return _contractDocumentation;
    }

    //////////////////////////////
    /// ADMIN
    //////////////////////////////

    /// @notice isAdmin getter for a target index
    /// @param platformIndex target platform index
    /// @param account address to check
    function _isAdmin(uint256 platformIndex, address account) internal view returns (bool) {
        // Return true/false depending on whether account is an admin
        return roleInfo[platformIndex][account] != Roles.ADMIN ? false : true;
    }

    /// @notice isAdmin getter for a target index
    /// @param platformIndex target platform index
    /// @param account address to check
    function _isAdminOrManager(uint256 platformIndex, address account) internal view returns (bool) {
        // Return true/false depending on whether account is an admin or manager
        return roleInfo[platformIndex][account] != Roles.NO_ROLE ? true : false;
    }

    /// @notice Only allowed for contract admin
    /// @param platformIndex target platform index
    /// @dev only allows approved admin of platform index (from msg.sender)
    modifier onlyAdmin(uint256 platformIndex) {
        if (!_isAdmin(platformIndex, msg.sender)) {
            revert RequiresAdmin();
        }

        _;
    }

    /// @notice Only allowed for contract admin
    /// @param platformIndex target platform index
    /// @dev only allows approved managers or admins of platform index (from msg.sender)
    modifier onlyAdminOrManager(uint256 platformIndex) {
        if (!_isAdminOrManager(platformIndex, msg.sender)) {
            revert RequiresHigherRole();
        }

        _;
    }

    /// @notice Grants new roles for given platform index
    /// @param platformIndex target platform index
    /// @param roleDetails array of RoleDetails structs
    function grantRoles(uint256 platformIndex, RoleDetails[] memory roleDetails) external onlyAdmin(platformIndex) {
        // grant roles to each [account, role] provided
        for (uint256 i; i < roleDetails.length; ++i) {
            // check that role being granted is a valid role
            if (roleDetails[i].role > Roles.ADMIN) {
                revert RoleDoesntExist();
            }
            // give role to account
            roleInfo[platformIndex][roleDetails[i].account] = roleDetails[i].role;

            emit RoleGranted({
                platformIndex: platformIndex,
                sender: msg.sender,
                account: roleDetails[i].account,
                role: roleDetails[i].role
            });
        }
    }

    /// @notice Revokes roles for given platform index
    /// @param platformIndex target platform index
    /// @param accounts array of addresses to revoke roles from
    function revokeRoles(uint256 platformIndex, address[] memory accounts) external onlyAdmin(platformIndex) {
        // revoke roles from each account provided
        for (uint256 i; i < accounts.length; ++i) {
            // revoke role from account
            roleInfo[platformIndex][accounts[i]] = Roles.NO_ROLE;

            emit RoleRevoked({
                platformIndex: platformIndex,
                sender: msg.sender,
                account: accounts[i],
                role: Roles.NO_ROLE
            });
        }
    }

    /// @notice Get role for given platform index + account
    /// @param platformIndex target platform index
    /// @param account address to get role for
    /// @return Roles enum value
    function getRole(uint256 platformIndex, address account) external view returns (Roles) {
        return roleInfo[platformIndex][account];
    }

    //////////////////////////////
    /// PLATFORM THEMING
    //////////////////////////////

    /// @notice Create platform index -> string
    /// @dev Used to initialize string information for rendering
    /// @param account address account to give admin role for platformIndex
    /// @param uri uri to set metadata to
    function newPlatformIndex(address account, string memory uri) external {
        // increment platformIndex counter
        ++platformCounter;
        // cache platformCounter
        (uint256 currentPlatform, address sender) = (platformCounter, msg.sender);
        // set string for new platformIndex
        platformThemeInfo[currentPlatform] = uri;
        // grant admin role to account
        roleInfo[currentPlatform][account] = Roles.ADMIN;

        emit RoleGranted({platformIndex: currentPlatform, sender: sender, account: account, role: Roles.ADMIN});

        emit PlatformThemeUpdated({platformIndex: currentPlatform, sender: sender, newTheme: uri});
    }

    /// @notice Set platform theme -> string
    /// @dev Used to provide string information for rendering
    /// @param platformIndex target platform index
    /// @param uri uri to set metadata to
    function setPlatformTheme(uint256 platformIndex, string memory uri) external onlyAdminOrManager(platformIndex) {
        platformThemeInfo[platformIndex] = uri;
        emit PlatformThemeUpdated({platformIndex: platformIndex, sender: msg.sender, newTheme: uri});
    }

    /// @notice Getter for platformIndex -> uri string
    /// @param platformIndex target platform index
    /// @return address string for target
    function getPlatformTheme(uint256 platformIndex) external view returns (string memory) {
        return platformThemeInfo[platformIndex];
    }
}