// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.15;

import "@openzeppelin/access/Ownable.sol";


/**
 * @title Whitelist contract
 * @notice Contract responsible for managing whitelist of assets which are permited to have their transfer rights tokenized.
 *         Whitelist is temporarily solution for onboarding first users and will be dropped in the future.
 */
contract Whitelist is Ownable {

    /*----------------------------------------------------------*|
    |*  # VARIABLES & CONSTANTS DEFINITIONS                     *|
    |*----------------------------------------------------------*/

    /**
     * @notice Stored flag that incidates, whether ATR token minting is permited only to whitelisted assets.
     */
    bool public useWhitelist;

    /**
     * @notice Whitelist of asset addresses, which are permited to mint their transfer rights.
     * @dev Used only if `useWhitelist` flag is set to true.
     */
    mapping (address => bool) public isWhitelisted;

    /**
     * @notice Whitelist of library addresses, which are permited to be called via delegatecall.
     * @dev Always used, even if `useWhitelist` flag is set to false.
     */
    mapping (address => bool) public isWhitelistedLib;


    /*----------------------------------------------------------*|
    |*  # EVENTS & ERRORS DEFINITIONS                           *|
    |*----------------------------------------------------------*/

    /**
     * @dev Emitted when asset address is whitelisted.
     */
    event AssetWhitelisted(address indexed assetAddress, bool indexed isWhitelisted);


    /*----------------------------------------------------------*|
    |*  # CONSTRUCTOR                                           *|
    |*----------------------------------------------------------*/

    constructor() Ownable() {

    }


    /*----------------------------------------------------------*|
    |*  # GETTERS                                               *|
    |*----------------------------------------------------------*/

    /**
     * @notice Get if an asset can have its transfer rights tokenized.
     * @param assetAddress Address of asset which transfer rights should be tokenized.
     * @return True if asset is whitelisted or whitelist is not used at all.
     */
    function canBeTokenized(address assetAddress) external view returns (bool) {
        if (!useWhitelist)
            return true;

        return isWhitelisted[assetAddress];
    }


    /*----------------------------------------------------------*|
    |*  # SETTERS                                               *|
    |*----------------------------------------------------------*/

    /**
     * @notice Set if ATR token minting is restricted by the whitelist.
     * @dev Set `useWhitelist` stored flag.
     * @param _useWhitelist New `useWhitelist` flag value.
     */
    function setUseWhitelist(bool _useWhitelist) external onlyOwner {
        useWhitelist = _useWhitelist;
    }

    /**
     * @notice Set if asset address is whitelisted.
     * @dev Set `isWhitelisted` mapping value.
     * @param assetAddress Address of the whitelisted asset.
     * @param _isWhitelisted New `isWhitelisted` mapping value.
     */
    function setIsWhitelisted(address assetAddress, bool _isWhitelisted) public onlyOwner {
        isWhitelisted[assetAddress] = _isWhitelisted;

        emit AssetWhitelisted(assetAddress, _isWhitelisted);
    }

    /**
     * @notice Set if asset addresses from a list are whitelisted.
     * @dev Set `isWhitelisted` mapping value for every address in a list.
     * @param assetAddresses List of whitelisted asset addresses.
     * @param _isWhitelisted New `isWhitelisted` mapping value for every address in a list.
     */
    function setIsWhitelistedBatch(address[] calldata assetAddresses, bool _isWhitelisted) external onlyOwner {
        uint256 length = assetAddresses.length;
        for (uint256 i; i < length;) {
            setIsWhitelisted(assetAddresses[i], _isWhitelisted);
            unchecked { ++i; }
        }
    }

    /**
     * @notice Set if library address is whitelisted.
     * @dev Set `isWhitelistedLib` mapping value.
     * @param libAddress Address of the whitelisted library.
     * @param _isWhitelisted New `isWhitelisted` mapping value.
     */
    function setIsWhitelistedLib(address libAddress, bool _isWhitelisted) public onlyOwner {
        isWhitelistedLib[libAddress] = _isWhitelisted;
    }

}