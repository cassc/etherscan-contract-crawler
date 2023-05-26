// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
    @title Whitelist
    @dev Allows developers to implement whitelisting functionality
    @dev Inherits methods and variables from AccessControl
    @dev WHITELISTER_ROLE is used to grant permissions for whitelist control
    @dev Use `.grantRole` method from AccessControl to give a whitelister role

    Use `onlyWhitelisted` modifier for a method in order to restrict access
    only for whitelisted addresses:

    ```
        contract MyContract is Whitelist {
            function deposit() external onlyWhitelisted {
                // allow execution only to addresses that are in the whitelist
            }
        }
    ```

    Addresses can be added and removed dynamically via the `addToWhitelist`
    and `removeFromWhitelist` functions. You can check if an address is
    whitelisted or not by calling `isWhitelisted` function.

    The entire whitelist functionality can be enabled or disabled via the
    `enableWhitelist` and `disableWhitelist` functions. You can check if the
    feature is enabled by calling `isWhitelistEnabled` function.

    The following events are emitted: Enabled, Disabled, AddressAdded, AddressRemoved
*/

contract Whitelist is AccessControl {
    /// @dev Emitted when whitelist feature is enabled
    event Enabled(address senderAddress);
    /// @dev Emitted when whitelist feature is disabled
    event Disabled(address senderAddress);
    /// @dev Emitted when an address is added to the whitelist
    event AddressAdded(address addedAddress);
    /// @dev Emitted when an address is removed from the whitelist
    event AddressRemoved(address removedAddress);

    /// @notice Whitelister role is used for whitelist administration
    bytes32 public constant WHITELISTER_ROLE = keccak256("WHITELISTER_ROLE");

    bool private _isWhitelistEnabled = true;
    mapping (address => bool) private _whitelist;

    /// @dev Restricts access only for Whitelister and Admin
    modifier onlyWhitelisterOrAdmin() {
        _onlyWhitelisterOrAdmin();
        _;
    }

    /// @dev Restricts access only for whitelisted addresses
    modifier onlyWhitelisted() {
        _onlyWhitelisted();
        _;
    }

    /**
        @notice Enables whitelist feature
        @dev The caller must have Whitelister or Admin role
        @dev Enables whitelist if disabled and emits `Enabled` event
     */
    function enableWhitelist() public onlyWhitelisterOrAdmin {
        require(!isWhitelistEnabled(), "Whitelist is already enabled");
        _isWhitelistEnabled = true;
        emit Enabled(msg.sender);
    }

    /**
        @notice Disables whitelist feature
        @dev The caller must have Whitelister or Admin role
        @dev Disables whitelist if enabled and emits `Disabled` event
     */
    function disableWhitelist() public onlyWhitelisterOrAdmin {
        require(isWhitelistEnabled(), "Whitelist is already disabled");
        _isWhitelistEnabled = false;
        emit Disabled(msg.sender);
    }

    /**
        @notice Returns true if whitelist feature is enabled
        @return bool Value indicating whether whitelist is enabled or not
     */
    function isWhitelistEnabled() public view returns (bool) {
        return _isWhitelistEnabled;
    }

    /**
        @notice Adds an address to the whitelist
        @dev The caller must have Whitelister or Admin role
        @dev Adds an address if not whitelisted and emits `AddressAdded` event
        @param addressToAdd Address that is added to the whitelist
     */
    function addToWhitelist(address addressToAdd) public onlyWhitelisterOrAdmin {
        require(!isWhitelisted(addressToAdd), "Address to add is already whitelisted");
        _whitelist[addressToAdd] = true;
        emit AddressAdded(addressToAdd);
    }

    /**
        @notice Removes an address from the whitelist
        @dev The caller must have Whitelister or Admin role
        @dev Removes a whitelisted address and emits `AddressAdded` event
        @param addressToRemove Address that is removed from the whitelist
     */
    function removeFromWhitelist(address addressToRemove) public onlyWhitelisterOrAdmin {
        require(isWhitelisted(addressToRemove), "Address to remove is not whitelisted");
        _whitelist[addressToRemove] = false;
        emit AddressRemoved(addressToRemove);
    }

    /**
        @notice Returns true if address is whitelisted
        @param addressToCheck Address to check
        @return bool Value indicating whether whitelist contains an address or not
     */
    function isWhitelisted(address addressToCheck) public view returns (bool) {
        return _whitelist[addressToCheck] == true;
    }

    /// @dev Checks if method caller has Whitelister or Admin role
    function _onlyWhitelisterOrAdmin() private view {
        require(hasRole(WHITELISTER_ROLE, msg.sender)
            || hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Sender doesn't have Whitelister or Admin role");
    }

    /// @dev Checks if method caller is whitelisted
    function _onlyWhitelisted() private view {
        if (isWhitelistEnabled() && !isWhitelisted(msg.sender))
            revert("Sender address is not whitelisted");
    }
}