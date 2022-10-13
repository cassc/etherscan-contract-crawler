//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../structs/MembershipPlansStruct.sol";

/**
 * @title IMembershipFactory
 * @dev Interface to interact with Membership Factory
 *
 */
interface IAssetStoreFactory {
    /**
     * @dev Function to deployAssetStore for each user
     * @param _uid string identifier of the user across the dApp
     * @param _user address of the user deploying the AssetStore
     *
     */
    function deployAssetStore(string memory _uid, address _user) external;

    /**
     * @dev Function to return assetStore Address of a specific user
     * @param _uid string identifier for the user across the dApp
     * @return address of the AssetStore for given user
     *
     */
    function getAssetStoreAddress(string memory _uid)
        external
        view
        returns (address);
}