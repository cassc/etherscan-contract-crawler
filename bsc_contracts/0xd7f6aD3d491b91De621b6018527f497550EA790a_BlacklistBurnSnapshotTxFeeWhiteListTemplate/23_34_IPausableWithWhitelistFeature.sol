// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev ERC20 token with a Whitelist and Pause feature
 */
interface IPausableWithWhitelistFeature {

    /**
     * @dev Gives WHITELISTED_FROM_ROLE to `addresses`. 
     */
    function addAddressesToWhitelistFrom(address[] calldata addresses) external;

    /**
     * @dev Removes WHITELISTED_FROM_ROLE from `addresses`.
     */
    function removeAddressesFromWhitelistFrom(address[] calldata addresses) external;

    /**
     * @dev Gives WHITELISTED_SENDER_ROLE to `addresses`.
     */
    function addAddressesToWhitelistSender(address[] calldata addresses) external;

    /**
     * @dev Removes WHITELISTED_SENDER_ROLE from `addresses`.
     */    
    function removeAddressesFromWhitelistSender(address[] calldata addresses) external;

    /**
     * @notice Pause the token transfers
     */
    function pause() external;

    /**
     * @notice Unpause the token transfers
     */
    function unpause() external;

}