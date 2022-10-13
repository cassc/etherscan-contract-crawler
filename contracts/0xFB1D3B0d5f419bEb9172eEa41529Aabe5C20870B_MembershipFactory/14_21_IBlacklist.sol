//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title IBlacklist
 * @dev To interact with Blacklist Users Contracts
 */
interface IBlacklist {
    /**
     * @dev checkIfAddressIsBlacklisted
     * @param _user address of wallet to check is blacklisted
     *
     */
    function checkIfAddressIsBlacklisted(address _user) external view;

    /**
     * @dev Function to get blacklisted addresses
     * @return blackListAddresses address[]
     *
     */
    function getBlacklistedAddresses() external view returns (address[] memory);
}