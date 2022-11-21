//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "../interfaces/IWhitelist.sol";

/**
 * @title WhitelistUsers Contract
 * This contract contains information of which users are whitelisted
 * to interact with factory contracts and the rest of the protocol
 *
 *
 */
contract WhitelistUsers is
    IWhitelist,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @dev initialize - Initializes the function for Ownable and Reentrancy.
     * @param _duration uint256 how long the membership is for whitelisted users
     * @param _updates uint256 representing how many updates whitelist users get
     *
     */
    function initialize(uint256 _duration, uint96 _updates) public initializer {
        __Context_init_unchained();
        __Ownable_init();
        __ReentrancyGuard_init();

        whiteListUpdatesPerYear = _updates;
        whiteListDuration = _duration;
    }

    /// @dev whitelisted addresses
    address[] private whiteListAddresses;

    /// @dev whiteList duration
    uint256 whiteListDuration;

    /// @dev whiteList UpdatesPerYear given
    uint96 whiteListUpdatesPerYear;

    /**
     * @dev Function to get whitelisted addresses
     * @return list of addresses on the whitelist
     *
     */
    function getWhitelistAddress() external view returns (address[] memory) {
        return whiteListAddresses;
    }

    /**
     * @dev checkIfAddressIsWhitelisted
     * @param _user address of the user to verify is on the list
     * @return whitelisted boolean representing if the input is whitelisted
     *
     */
    function checkIfAddressIsWhitelisted(address _user)
        external
        view
        returns (bool whitelisted)
    {
        for (uint256 i = 0; i < whiteListAddresses.length; i++) {
            if (whiteListAddresses[i] == _user) {
                return whitelisted = true;
            }
        }
        whitelisted = false;
    }

    /**
     * @dev addWhiteList
     * @param _user address of the wallet to whitelist
     *
     */
    function addWhiteList(address _user) external onlyOwner {
        whiteListAddresses.push(_user);
    }

    /**
     * @dev bulkAddWhiteList
     * @param _users addresses of the wallets to whitelist
     *
     */
    function bulkAddWhiteList(address[] calldata _users) external onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whiteListAddresses.push(_users[i]);
        }
    }

    /**
     * @dev removeWhiteList
     * @param _user address of the wallet to remove from the whitelist
     *
     */
    function removeWhiteList(address _user) external onlyOwner {
        for (uint256 i; i < whiteListAddresses.length; i++) {
            if (whiteListAddresses[i] == _user) {
                whiteListAddresses[i] = whiteListAddresses[
                    whiteListAddresses.length - 1
                ];
                whiteListAddresses.pop();
                break;
            }
        }
    }

    /**
     * @dev getWhitelistUpdatesPerYear
     * @return whiteListUpdatesPerYear uint256 for how many updates the whitelisted gets
     *
     */
    function getWhitelistUpdatesPerYear() external view returns (uint96) {
        return whiteListUpdatesPerYear;
    }

    /**
     * @dev getWhitelistDuration
     * @return whiteListDuration uint256 of how long the membership is for whitelisted users
     */
    function getWhitelistDuration() external view returns (uint256) {
        return whiteListDuration;
    }

    /**
     * @dev setWhitelistUpdatesPerYear
     * @param _updatesPerYear uint256 set how many updates a whitelisted user gets within a year
     *
     */
    function setWhitelistUpdatesPerYear(uint96 _updatesPerYear)
        external
        onlyOwner
    {
        whiteListUpdatesPerYear = _updatesPerYear;
    }

    /**
     * @dev setWhitelistDuration
     * @param _duration uint256 change the value of how long whitelisted memberships are
     */
    function setWhitelistDuration(uint256 _duration) external onlyOwner {
        whiteListDuration = _duration;
    }
}