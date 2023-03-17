// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title CentBaseWhitelistBETA.
/// @author @Dadogg80.
/// @notice CentBaseWhitelistBETA is used to whitelist accounts and collections to be
///         interacting with the Centaurify NFT marketplace.

/// @notice This smart contract is one of the smart contracts for the BETA release.  

contract CentBaseWhitelistBETA is AccessControl, Ownable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    
    /// @dev Array with whitelisted accounts.
    address[] private whitelisted_users;
    address[] private whitelisted_collections;
    
    mapping(address => bool) public isWhitelistedUser;
    mapping(address => bool) public isWhitelistedCollection;
    
    /// @dev Error: Not authorized.
    error Code_1();
    error Code_2();

    /// @dev Modifier used to check if msg.sender is whitelisted. 
    modifier onlyWhitelistedUsers() {
        if (!isWhitelistedUser[msg.sender]) revert Code_1();
        _;
    }
    /// @dev Modifier used to check if msg.sender is whitelisted. 
    modifier onlyWhitelistedCollections(address collection) {
        if (!isWhitelistedCollection[collection]) revert Code_2();
        _;
    }

    /// @notice Return the array with whitelisted accounts.
    /// @dev Can only be called by an whitelisted account.
    function getUsersList() external view returns (address[] memory){
        return whitelisted_users;
    }

        /// @notice Return the array with whitelisted collections.
    function getCollectionsList() external view returns (address[] memory){
        return whitelisted_collections;
    }

    /// @notice Whitelist an account.
    /// @param accounts The address of account to whitelist.
    /// @dev Only the owner account, can add new accounts to the whitelist.
    function whitelistUsers(address[] calldata accounts) external onlyRole(OPERATOR_ROLE) {
        for (uint i = 0; i < accounts.length; i++) {
            isWhitelistedUser[payable(address(accounts[i]))] = true;
            whitelisted_users.push(payable(accounts[i]));
        }
    }

    /// @notice Whitelist a list of collection.
    /// @param collections The address of collection to whitelist.
    /// @dev Only the whitelist owner can add a new collection
    function whitelistCollections(address[] calldata collections) external onlyRole(OPERATOR_ROLE) {
         for (uint i = 0; i < collections.length; i++) {
            isWhitelistedCollection[collections[i]] = true;
            whitelisted_collections.push(collections[i]);
        }
    }

    function removeUser(address user) external onlyRole(OPERATOR_ROLE) {
        isWhitelistedUser[user] = false;
    }

    function removeCollection(address collection) external onlyRole(OPERATOR_ROLE) {
        isWhitelistedCollection[collection] = false;
    }

}