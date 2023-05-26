// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IAdministrable {
    /**
     * @dev set new trusted forwarder of EIP2771Recipient
     * @param forwarder new address of trusted forwarder
     */
    function setTrustedForwarder(address forwarder) external;

    /**
     * @dev pause all transfer
     */
    function pause() external;

    /**
     * @dev unpause all transfer
     */
    function unpause() external;

    /**
     * @dev add accounts to blacklists
     * @param accounts the list of accounts to add to blacklists
     */
    function addBlacklists(address[] calldata accounts) external;

    /**
     * @dev remove accounts from blacklists
     * @param accounts the list of accounts to remove from blacklists
     */
    function removeBlacklists(address[] calldata accounts) external;
}