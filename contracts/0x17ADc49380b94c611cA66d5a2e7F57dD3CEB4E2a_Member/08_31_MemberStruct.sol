//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Member Structure stores all member information
 * @param uid string For storing UID that cross references UID from DB for loading off-chain data
 * @param dateCreated uint256 timestamp of creation of User
 * @param wallets address[] Maintains an array of backUpWallets of the User
 * @param primaryWallet uint256 index of where in the wallets array the primary wallet exists
 */
struct member {
    uint256 dateCreated;
    address[] wallets;
    address[] backUpWallets;
    uint256 primaryWallet;
    string uid;
}