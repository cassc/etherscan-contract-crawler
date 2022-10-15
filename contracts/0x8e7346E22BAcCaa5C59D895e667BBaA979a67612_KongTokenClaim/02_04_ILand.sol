// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/**
 * @title  Interface for $LAND Token Contract.
 */
interface ILand {

    // Add an address to the whitelist.
    function addWhitelistAddress(address transferer) external;

    // Remove an address from the whitelist.
    function removeWhitelistAddress(address transferer) external;

    // See if an address is on the whitelist.
    function onWhitelist(address transferer) external view returns (bool);

    // Allow the DAO to remove transfer restrictions.
    function unlockTransfer() external;

    // See if the sender is either on a whiteliss or if they have at least one $CITIZEN.
    function _validSender(address from) external view returns (bool);

    // See if the recipient is either on a whiteliss or if they have at least one $CITIZEN.
    function _validRecipient(address to) external view returns (bool);

    // Mind $LAND token.
    function mint(address to, uint256 amount) external;
}