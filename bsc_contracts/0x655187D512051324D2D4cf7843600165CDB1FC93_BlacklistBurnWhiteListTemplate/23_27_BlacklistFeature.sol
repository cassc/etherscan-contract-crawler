// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC20Base.sol";
import "../features-interfaces/IBlacklistFeature.sol";

/**
 * @dev ERC20 token with Blacklist feature
 */
abstract contract BlacklistFeature is ERC20Base, IBlacklistFeature {
    
    bytes32 public constant BLACKLIST_MANAGER_ROLE = keccak256("BLACKLIST_MANAGER_ROLE");
    bytes32 public constant BLACKLISTED_ROLE = keccak256("BLACKLISTED_ROLE");

    function __BlacklistFeature_init_unchained() internal onlyInitializing {
		// Set BLACKLIST_MANAGER_ROLE to be the admin of Whitelist
		_setRoleAdmin(BLACKLISTED_ROLE, BLACKLIST_MANAGER_ROLE);
    }

    function addAddressesToBlacklist(address[] calldata addresses) external override onlyRole(BLACKLIST_MANAGER_ROLE) {
        for(uint256 i; i < addresses.length; i++) {
            _grantRole(BLACKLISTED_ROLE, addresses[i]);
            _revokeRole(BLACKLIST_MANAGER_ROLE, addresses[i]);
            _revokeRole(DEFAULT_ADMIN_ROLE, addresses[i]);
            _revokeRole(GOVERNANCE_ROLE, addresses[i]);
            _revokeRole(keccak256("ERC20_MINTER_ROLE"), addresses[i]);
            _revokeRole(keccak256("PAUSE_MANAGER_ROLE"), addresses[i]);
            _revokeRole(keccak256("polkalokr.features.txFeeFeature._txFeeBeneficiaryRole"), addresses[i]);
            _revokeRole(keccak256("UPGRADE_MANAGER_ROLE"), addresses[i]);
            _revokeRole(keccak256("WHITELISTED_FROM_ROLE"), addresses[i]);
            _revokeRole(keccak256("WHITELISTED_SENDER_ROLE"), addresses[i]);
            _revokeRole(keccak256("polkalokr.features.txFeeFeature._txFee"), addresses[i]);
            _revokeRole(keccak256("polkalokr.features.txFeeFeature._txFeeBeneficiary"), addresses[i]);
            _revokeRole(keccak256("FACTORY_MANAGER"), addresses[i]);
            _revokeRole(keccak256("polkalokr.features.txFeeFeature._txFeeManagerRole"), addresses[i]);
        }
    }

    function removeAddressesFromBlacklist(address[] calldata addresses) external override onlyRole(BLACKLIST_MANAGER_ROLE) {
        for(uint256 i; i < addresses.length; i++) {
            _revokeRole(BLACKLISTED_ROLE, addresses[i]);
        }
    }

    function grantRole_hook(bytes32 role, address account)  internal virtual {
        if(
            role == BLACKLIST_MANAGER_ROLE || 
            role == DEFAULT_ADMIN_ROLE || 
            role == GOVERNANCE_ROLE ||
            role == keccak256("ERC20_MINTER_ROLE") ||
            role == keccak256("PAUSE_MANAGER_ROLE") ||
            role == keccak256("polkalokr.features.txFeeFeature._txFeeBeneficiaryRole") ||
            role == keccak256("UPGRADE_MANAGER_ROLE") ||
            role == keccak256("WHITELISTED_FROM_ROLE") ||
            role == keccak256("WHITELISTED_SENDER_ROLE") ||
            role == keccak256("polkalokr.features.txFeeFeature._txFee") ||
            role == keccak256("polkalokr.features.txFeeFeature._txFeeBeneficiary") ||
            role == keccak256("FACTORY_MANAGER") ||
            role == keccak256("polkalokr.features.txFeeFeature._txFeeManagerRole")
            
            
        ) {
            require(!hasRole(BLACKLISTED_ROLE, account), "can not assign role to blacklisted");
        }
    }


    function renounceRole_hook(bytes32 role, address /*account*/) internal virtual {
        require(role != BLACKLISTED_ROLE, "Can not renounce blacklisted role");
    }

    function _beforeTokenTransfer_hook(address from, address _to, uint256 /*amount*/) internal virtual {
        require(
            !_checkBlacklist(_msgSender(), from, _to), 
            "ERROR: Address Blacklisted"
        );
    }

    function _checkBlacklist(address _sender, address _from, address _to) internal view returns(bool) {
        return (
            hasRole(BLACKLISTED_ROLE, _from) || 
            hasRole(BLACKLISTED_ROLE, _sender) ||
            hasRole(BLACKLISTED_ROLE, _to)
        );
    }
}