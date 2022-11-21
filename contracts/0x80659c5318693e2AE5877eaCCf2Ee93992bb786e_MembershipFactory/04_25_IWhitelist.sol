//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Interface for IWhitelist to interact with Whitelist Users Contracts
 *
 */
interface IWhitelist {
    /**
     * @dev getWhitelistUpdatesPerYear
     * @return whiteListUpdatesPerYear uint256 for how many updates the whitelisted gets
     *
     */
    function getWhitelistUpdatesPerYear() external view returns (uint96);

    /**
     * @dev getWhitelistDuration
     * @return whiteListDuration uint256 of how long the membership is for whitelisted users
     */
    function getWhitelistDuration() external view returns (uint256);

    /**
     * @dev checkIfAddressIsWhitelisted
     * @param _user address of the user to verify is on the list
     * @return whitelisted boolean representing if the input is whitelisted
     *
     */
    function checkIfAddressIsWhitelisted(address _user)
        external
        view
        returns (bool whitelisted);

    /**
     * @dev Function to get whitelisted addresses
     * @return list of addresses on the whitelist
     *
     */
    function getWhitelistAddress() external view returns (address[] memory);

    /**
     * @dev bulkAddWhiteList
     * @param _users addresses of the wallets to whitelist
     *
     */
    function bulkAddWhiteList(address[] calldata _users) external;
}