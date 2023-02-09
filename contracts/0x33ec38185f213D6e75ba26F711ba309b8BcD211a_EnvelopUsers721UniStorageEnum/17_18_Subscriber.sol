// SPDX-License-Identifier: MIT
// ENVELOP(NIFTSY) protocol V1 for NFT. Subscriber 
// abstract contract implements subscribing features.
// For use in cases with subscription

/// @title Subscriber abstract contract 
/// @author Envelop project Team
/// @notice Abstract contract implements subscribing features.
/// For use in cases with subscription
/// @dev Using _serviceCode param:
///       0 - simple saftNFT subscription       
///     100 - mint service                      
/// also we can think about _serviceCode as uniq code of  service (saft, mint etc)
/// !!! use Ownable pattern for `setSubscriptionManager`
pragma solidity 0.8.16;

import "ISubscriptionManager.sol";

abstract contract Subscriber {

	uint256 immutable public SERVICE_CODE;
	ISubscriptionManager public subscriptionManager;

	constructor(uint256 _code) {
		SERVICE_CODE = _code;
	}

	function _setSubscriptionManager(address _manager) internal {
        require(_manager != address(0),'Non zero only');
        subscriptionManager = ISubscriptionManager(_manager);
    }
    

    function _checkAndFixSubscription(address _user) 
        internal 
        returns (bool ok) 
    {
        if (address(subscriptionManager) != address(0)){
            ok = subscriptionManager.checkAndFixUserSubscription(
                _user,
                SERVICE_CODE  
            );
            return ok;
        }
    }

    function _fixUserSubscription(
        address _user, 
        uint256 _tariffIndex
    ) internal {
    	if (address(subscriptionManager) != address(0)){
            subscriptionManager.fixUserSubscription(
                _user,
                _tariffIndex  
            );
        }
    }

    function _checkUserSubscription(address _user) 
        internal 
        view 
        returns (bool ok)
    {
        if (address(subscriptionManager) != address(0)){
            ok = subscriptionManager.checkUserSubscription(
                _user,
                SERVICE_CODE  
            );
            return ok;
        }
    }
}