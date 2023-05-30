// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IOtoCoMaster.sol";

interface IOtoCoPlugin {

    /**
     * Plugin initializer with a function template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to create a new instance of plugin.
     */
    function addPlugin(uint256 seriesId, bytes calldata pluginData) external payable;

    /**
     * Allow attach a previously deployed plugin if possible
     * @dev This function should run enumerous amounts of verifications before allow the attachment.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function attachPlugin(uint256 seriesId, bytes calldata pluginData) external payable;

    /**
     * Plugin initializer with a function template to be used.
     * @dev To decode initialization data use i.e.: (string memory name) = abi.decode(pluginData, (string));
     *
     * @param pluginData The parameters to remove a instance of the plugin.
     */
    function removePlugin(uint256 seriesId, bytes calldata pluginData) external payable;
}