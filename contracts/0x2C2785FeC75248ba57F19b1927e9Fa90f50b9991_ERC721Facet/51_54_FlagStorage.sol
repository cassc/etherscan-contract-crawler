// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 *  ╔╗  ╔╗╔╗      ╔╗ ╔╗     ╔╗
 *  ║╚╗╔╝╠╝╚╗     ║║ ║║     ║║
 *  ╚╗║║╔╬╗╔╬═╦╦══╣║ ║║  ╔══╣╚═╦══╗
 *   ║╚╝╠╣║║║╔╬╣╔╗║║ ║║ ╔╣╔╗║╔╗║══╣
 *   ╚╗╔╣║║╚╣║║║╚╝║╚╗║╚═╝║╔╗║╚╝╠══║
 *    ╚╝╚╝╚═╩╝╚╩══╩═╝╚═══╩╝╚╩══╩══╝
 */

/**
 * @title  FlagStorage
 * @author slvrfn
 * @notice Library responsible for loading the associated "layout" from storage, and setting/retrieving
 *         the internal fields.
 */
library FlagStorage {
    struct Layout {
        mapping(uint256 => uint256) flagBits;
    }

    bytes32 internal constant STORAGE_SLOT = keccak256("genesis.libraries.storage.FlagStorage");

    /**
     * @notice Obtains the FlagStorage layout from storage.
     * @dev    layout is stored at the chosen STORAGE_SLOT.
     */
    function layout() internal pure returns (Layout storage f) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            f.slot := slot
        }
    }

    /**
     * @dev    Obtains the 256-bit feature-flag bitmask associated with a flagGroup
     * @param  flagGroup - the group of flags to lookup.
     */
    function _flagBits(Layout storage f, uint256 flagGroup) internal view returns (uint256) {
        return f.flagBits[flagGroup];
    }

    /**
     * @dev    Checks if the feature-flag(s) bitmask associated with a flagGroup is are unset.
     * @param  flagGroup - the group of flags to lookup.
     */
    function _flagBitsUnset(Layout storage f, uint256 flagGroup, uint256 notMatchBits) internal view returns (bool) {
        // check notMatchBits are NOT SET
        return (f.flagBits[flagGroup] & notMatchBits) == 0;
    }

    /**
     * @dev    Updates the 256-bit feature-flag bitmask associated with a flagGroup.
     * @param  flagGroup - the group of flags to lookup.
     */
    function _setFlagBits(Layout storage f, uint256 flagGroup, uint256 bits) internal {
        f.flagBits[flagGroup] = bits;
    }
}