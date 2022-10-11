// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./TokenRecipient.sol";
import "./OwnedUpgradeabilityStorage.sol";
import "./ProxyRegistry.sol";
import "../../utils/libraries/Market.sol";

contract AuthenticatedProxy is TokenRecipient, OwnedUpgradeabilityStorage {
    bool initialized = false;
    address public user;
    ProxyRegistry public registry;
    bool public revoked;

    event Revoked(bool revoked);

    /**
     * Initialize an AuthenticatedProxy
     * @param addrUser Address of user on whose behalf this proxy will act
     * @param addrRegistry Address of ProxyRegistry contract which will manage this proxy
     */
    function initialize(address addrUser, ProxyRegistry addrRegistry) public {
        require(!initialized);
        initialized = true;
        user = addrUser;
        registry = addrRegistry;
    }

    /**
     * Set the revoked flag (allows a user to revoke ProxyRegistry access)
     * @dev Can be called by the user only
     * @param revoke Whether or not to revoke access
     */
    function setRevoke(bool revoke) public {
        require(_msgSender() == user);
        revoked = revoke;
        emit Revoked(revoke);
    }

    /**
     * Execute a message call from the proxy contract
     * @dev Can be called by the user, or by a contract authorized by the registry as long as the user has not revoked access
     * @param dest Address to which the call will be sent
     * @param howToCall Which kind of call to make
     * @param callData Calldata to send
     * @return result bool Result of the call (success or failure)
     */
    function proxy(
        address dest,
        Market.HowToCall howToCall,
        bytes memory callData
    ) public returns (bool result) {
        require(
            _msgSender() == user || (!revoked && registry.contracts(_msgSender())));

        if (howToCall == Market.HowToCall.Call) {
            (result, ) = dest.call(callData);
        } else if (howToCall == Market.HowToCall.DelegateCall) {
            (result, ) = dest.delegatecall(callData);
        }
    }

    /**
     * Execute a message call and assert success
     * @dev Same functionality as `proxy`, just asserts the return value
     * @param dest Address to which the call will be sent
     * @param howToCall What kind of call to make
     * @param callData Calldata to send
     */
    function proxyAssert(
        address dest,
        Market.HowToCall howToCall,
        bytes memory callData
    ) public {
        require(proxy(dest, howToCall, callData));
    }
}