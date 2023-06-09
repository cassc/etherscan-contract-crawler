// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import {Konstants} from "./Konstants.sol";
import {IKODABaseUpgradeable} from "./interfaces/IKODABaseUpgradeable.sol";

/**
 * @dev Base contract for KnownOrigin Creator NFT minting contracts
 *
 * - requires IKODABaseUpgradable interface for errors and events
 * - requires OpenZeppelin upgradable contracts to make inheriting contracts ownable and pausable
 *
 * - includes storage of default secondary marketplace royalties and additionally enabled minting addresses managed by the owner
 */
abstract contract KODABaseUpgradeable is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Konstants,
    IKODABaseUpgradeable
{
    /**
     * @notice Default Royalty Percentage for Secondary Sales
     * @dev default percentage value used to calculate royalty consideration on secondary sales stored with the same precision as `MODULO`
     */
    uint256 public defaultRoyaltyPercentage;

    // * Upgradeable Init * //

    /**
     * @notice Initialise the base contract with the default royalty percentage
     * @dev the inheriting contract must call otherwise the secondary royalty will be zero
     * @param _initialRoyaltyPercentage percentage to initially set the contract default royalty
     */
    function __KODABase_init(uint256 _initialRoyaltyPercentage) internal {
        __ReentrancyGuard_init();
        _updateDefaultRoyaltyPercentage(_initialRoyaltyPercentage);
    }

    // * OWNER * //

    /// @notice Allows the owner to pause some contract actions
    function pause() external onlyOwner whenNotPaused {
        _pause();
    }

    /// @notice Allows the owner to unpause
    function unpause() external onlyOwner whenPaused {
        _unpause();
    }

    /**
     * @notice Set the default royalty percentage to `_percentage`
     * @dev allows the owner to set {defaultRoyaltyPercentage}
     * @param _percentage the value to set with the same precision as {KODASettings-MODULO}
     */
    function updateDefaultRoyaltyPercentage(
        uint256 _percentage
    ) external onlyOwner {
        _updateDefaultRoyaltyPercentage(_percentage);
    }

    // * INTERNAL * //

    /// @dev Internal method for updating the the secondary royalty percentage used for calculating royalty for external marketplaces
    function _updateDefaultRoyaltyPercentage(uint256 _percentage) internal {
        if (_percentage > MAX_ROYALTY_PERCENTAGE)
            revert MaxRoyaltyPercentageExceeded();
        defaultRoyaltyPercentage = _percentage;
        emit DefaultRoyaltyPercentageUpdated(_percentage);
    }
}