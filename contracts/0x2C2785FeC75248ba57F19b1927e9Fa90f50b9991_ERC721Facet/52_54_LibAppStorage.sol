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
 * @title  LibAppStorage
 * @author slvrfn
 * @notice Library responsible for loading the associated AppStorage from storage, and setting/retrieving
 *         the internal fields.
 */
library LibAppStorage {
    struct AppStorage {
        uint32 maxTokens;
        address royaltyRecipient;
        uint16 royaltyPct; // stored as an integer, where 1 = 0.01%
    }

    /**
     * @notice Obtains the AppStorage layout from storage.
     * @dev    layout is stored at position 0.
     */
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}