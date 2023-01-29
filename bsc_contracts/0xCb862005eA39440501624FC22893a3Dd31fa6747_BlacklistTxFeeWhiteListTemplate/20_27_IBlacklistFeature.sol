// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev ERC20 token with a blacklist feature
 */
interface IBlacklistFeature {

    /**
     * @dev Add to blacklist all `addresses`, should to be called by a BLACKLIST_MANAGER_ROLE.
     */
    function addAddressesToBlacklist(address[] calldata addresses) external;
    
    /**
     * @dev Remove from blacklist all `addresses`, should to be called by a BLACKLIST_MANAGER_ROLE.
     */
    function removeAddressesFromBlacklist(address[] calldata addresses) external;

}