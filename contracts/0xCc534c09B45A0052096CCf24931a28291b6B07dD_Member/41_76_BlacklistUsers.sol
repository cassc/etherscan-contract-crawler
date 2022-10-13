//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IBlacklist.sol";
import "../libraries/Errors.sol";

/**
 * @title Blacklist
 * Contract storing addresses of users who are not able
 * to interact with the ecosystem at certain points
 *
 */
contract Blacklist is
    IBlacklist,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     */
    function initialize() public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();
    }

    /// @dev blacklisted addresses list
    address[] private blackListAddresses;

    /**
     * @dev Function to get blacklisted addresses
     * @return blackListAddresses address[]
     *
     */
    function getBlacklistedAddresses()
        external
        view
        returns (address[] memory)
    {
        return blackListAddresses;
    }

    /**
     * @dev checkIfAddressIsBlacklisted
     * @param _user address of wallet to check is blacklisted
     *
     */
    function checkIfAddressIsBlacklisted(address _user) external view {
        for (uint256 i = 0; i < blackListAddresses.length; i++) {
            if (blackListAddresses[i] == _user) {
                revert(Errors.BL_BLACKLISTED);
            }
        }
    }

    /**
     * @dev Function to add new wallet to blacklist
     * @param _user address of new blacklisted wallet
     *
     */
    function addBlacklist(address _user) external onlyOwner {
        blackListAddresses.push(_user);
    }

    /**
     * @dev Function to remove blacklist
     * @param _user address of user to remove from the list
     *
     */
    function removeBlacklist(address _user) external onlyOwner {
        for (uint256 i; i < blackListAddresses.length; i++) {
            if (blackListAddresses[i] == _user) {
                blackListAddresses[i] = blackListAddresses[
                    blackListAddresses.length - 1
                ];
                blackListAddresses.pop();
                break;
            }
        }
    }
}