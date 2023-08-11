// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FlagStorage} from "../libraries/storage/FlagStorage.sol";

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  FeatureFlag
 * @author slvrfn
 * @notice Abstract contract which contains logic to manage FeatureFlags across a Diamond.
 * @dev    This contract is meant to be inherited by contracts so they can use the shared FeatureFlag behavior.
 */
abstract contract FeatureFlag {
    using FlagStorage for FlagStorage.Layout;

    // Flag used to pause all contract functionality
    uint256 internal constant PAUSED_FLAG_BIT = 1 << 0;
    // Flag used to pause all token functionality
    uint256 internal constant TOKEN_FLAG_BIT = 1 << 1;

    // More specificFlags used at time of contract deployment
    uint256 internal constant MINT_FLAG_BIT = 1 << 2;
    uint256 internal constant REVEAL_FLAG_BIT = 1 << 3;
    uint256 internal constant MIX_FLAG_BIT = 1 << 4;
    uint256 internal constant COMBINE_FLAG_BIT = 1 << 5;
    uint256 internal constant SEED_BIT = 1 << 6;

    /**
     * @dev Emitted when a given feature flag is updated by address.
     */
    event FlagUpdate(uint256 indexed flagGroup, uint256 value, address operator);

    /**
     * @dev Raised when checking if a Feature is enabled.
     */
    error FlagMismatch();

    /**
     * @dev   Returns whether the group of flags in _flagGroup have the expected bits unset.
     *        This allows to check that bits in a particular _flagGroup are in the expected state (unset).
     *        If a bit is set, that means the feature is disabled.
     * @param flagGroup - the group of flags to be returned.
     */
    function _getFlagGroupBits(uint256 flagGroup) internal view returns (uint256) {
        return FlagStorage.layout()._flagBits(flagGroup);
    }

    /**
     * @dev   Returns whether the group of flags in _flagGroup have the expected bits unset.
     *        This allows to check that bits in a particular _flagGroup are in the expected state (unset).
     *        If a bit is set, that means the feature is disabled.
     * @param flagGroup - the group of flags to be evaluated.
     * @param notMatchBits - 256-bit bitmap to be checked.
     */
    function _flagBitsUnset(uint256 flagGroup, uint256 notMatchBits) internal view returns (bool) {
        return FlagStorage.layout()._flagBitsUnset(flagGroup, notMatchBits);
    }

    /**
     * @dev   Checks that bits relating to certain feature flags are unset (enabled), and reverts otherwise
     * @param flagGroup - the group of flags to be evaluated.
     * @param notMatchBits - 256-bit bitmap to be checked.
     */
    function _requireFeaturesEnabled(uint256 flagGroup, uint256 notMatchBits) internal view {
        if (!_flagBitsUnset(flagGroup, notMatchBits)) {
            revert FlagMismatch();
        }
    }

    /**
     * @dev   Updates the stored set of bits _flagGroup to be _value. This allows the simultaneous update of
     *        multiple flags in the same group
     * @param flagGroup - the group of flags to be evaluated.
     * @param bits - 256-bit bitmap to be assigned.
     */
    function _setFeatureFlag(uint256 flagGroup, uint256 bits) internal {
        FlagStorage.Layout storage f = FlagStorage.layout();
        f._setFlagBits(flagGroup, bits);
        emit FlagUpdate(flagGroup, bits, msg.sender);
    }
}