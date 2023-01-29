// SPDX-License-Identifier: MIT
// Add upgradeToAndCall(address newImplementation, bytes memory data) from UUPS to upgrade
pragma solidity ^0.8.0;

import "../security/PausableUpgradeableRewrited.sol";
import "../features-interfaces/IPausableWithWhitelistFeature.sol";
import "../ERC20Base.sol";

/**
 * @dev ERC20 token with a Pausable feature
 */
abstract contract PausableWithWhitelistFeature is 
    ERC20Base, 
    PausableUpgradeableRewrited, 
    IPausableWithWhitelistFeature 
{

    bytes32 public constant PAUSE_MANAGER_ROLE = keccak256("PAUSE_MANAGER_ROLE");
    bytes32 public constant WHITELISTED_FROM_ROLE = keccak256("WHITELISTED_FROM_ROLE");
    bytes32 public constant WHITELISTED_SENDER_ROLE = keccak256("WHITELISTED_SENDER_ROLE");

    function __PausableWithWhitelistFeature_init_unchained() internal onlyInitializing {
		// Set PAUSE_MANAGER_ROLE to be the admin of Whitelist
		_setRoleAdmin(WHITELISTED_FROM_ROLE, PAUSE_MANAGER_ROLE);
		_setRoleAdmin(WHITELISTED_SENDER_ROLE, PAUSE_MANAGER_ROLE);
    } 


    function addAddressesToWhitelistFrom(address[] calldata addresses) external override onlyRole(PAUSE_MANAGER_ROLE) {
        for(uint256 i; i < addresses.length; i++) {
            grantRole(WHITELISTED_FROM_ROLE, addresses[i]);
        }
    }

    function removeAddressesFromWhitelistFrom(address[] calldata addresses) external override onlyRole(PAUSE_MANAGER_ROLE) {
        for(uint256 i; i < addresses.length; i++) {
            revokeRole(WHITELISTED_FROM_ROLE, addresses[i]);
        }
    }

    function addAddressesToWhitelistSender(address[] calldata addresses) external override onlyRole(PAUSE_MANAGER_ROLE) {
        for(uint256 i; i < addresses.length; i++) {
            grantRole(WHITELISTED_SENDER_ROLE, addresses[i]);
        }
    }

    function removeAddressesFromWhitelistSender(address[] calldata addresses) external override onlyRole(PAUSE_MANAGER_ROLE) {
        for(uint256 i; i < addresses.length; i++) {
            revokeRole(WHITELISTED_SENDER_ROLE, addresses[i]);
        }
    }

    /**
     * @notice Pause the token transfers
     */
    function pause() external override onlyRole(PAUSE_MANAGER_ROLE) {
        _pause();
    }

    /**
     * @notice Unpause the token transfers
     */
    function unpause() external override onlyRole(PAUSE_MANAGER_ROLE) {
        _unpause();
    }


    function _beforeTokenTransfer_hook(address from, address /*_to*/, uint256 /*amount*/) internal virtual {
        require(!paused() || _checkWhitelist(from, _msgSender()), "ERC20Pausable: token transfer while paused");
        //super._beforeTokenTransfer(from, to, amount);
    }

    function _checkWhitelist(address _from, address _sender) internal view returns(bool) {
        return (hasRole(WHITELISTED_FROM_ROLE, _from) || hasRole(WHITELISTED_SENDER_ROLE, _sender));
    }

}