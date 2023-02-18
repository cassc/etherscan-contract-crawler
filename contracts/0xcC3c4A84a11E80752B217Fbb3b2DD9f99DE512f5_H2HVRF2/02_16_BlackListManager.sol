// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Blacklist manager
/// @author Luis Pando
/// @notice Manages the players that are blacklisted
/// @dev A player is blacklisted for all the raffles at once.
contract BlackListManager is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR");

    struct BlackListStruct {
        bool blacklisted;   // is blacklisted the user
        uint256 dateBlacklisted; // when was blacklisted for the first time
    }
    // map with the wallet of the player as key
    mapping(address => BlackListStruct) public blackList;

    constructor() {
        _setupRole(OPERATOR_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Add a player to the blacklist. The blacklist is common for all the raffles
    /// @dev the user could be added and removed from the blacklist several times, but the
    /// field dateBlacklisted will contain the date of when the user was added, even if was removed
    /// @param _player User that has suspicious behaviour and that will be blacklisted
    function addToBlackList(address _player) external onlyRole(OPERATOR_ROLE) {
        BlackListStruct memory blElement = BlackListStruct({
            blacklisted: true,
            dateBlacklisted: block.timestamp
        });
        blackList[_player] = blElement;
    }

    /// @notice remove a player from the blacklist
    /// @param _player that will be removed from the blacklist and will be able to buy entries again
    function removeFromBlackList(address _player)
        external
        onlyRole(OPERATOR_ROLE)
    {
        blackList[_player].blacklisted = false;
    }

    /// @notice returns if a player is in the blacklist
    /// @param _player User to check if blacklisted or not
    /// @return true if the user wallet is in the blacklist. False otherwise
    function isBlackListed(address _player) external view returns (bool) {
        return blackList[_player].blacklisted;
    }

    /// @notice returns the date (if any) when the user was blacklisted for first time
    /// @dev The returned value will exists even if the user was removed from the blacklist
    /// Do not use it without calling isBlacklisted first
    /// @param _player User to return the date when blacklisted
    /// @return a number with the epoch of when the player was blacklisted. 0 if never blacklisted
    function getBlackListedDate(address _player) external view returns (uint256) {
        return blackList[_player].dateBlacklisted;
    }
}