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
 * @title  TokenStorage
 * @author slvrfn
 * @notice Library responsible for loading the associated "layout" from storage, and setting/retrieving
 *         the internal fields.
 */
library TokenStorage {
    using TokenStorage for TokenStorage.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("genesis.libraries.storage.TokenStorage");

    struct Layout {
        string baseRelicUri;
        mapping(uint256 => mapping(uint256 => uint256)) tokenData;
    }

    /**
     * @notice Obtains the TokenStorage layout from storage.
     * @dev    layout is stored at the chosen STORAGE_SLOT.
     */
    function layout() internal pure returns (Layout storage t) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            t.slot := slot
        }
    }

    /**
     * @dev returns the current base Relic uri.
     */
    function _baseRelicUri(Layout storage t) internal view returns (string memory) {
        return t.baseRelicUri;
    }

    /**
     * @dev updates the current base Relic uri.
     */
    function _setBaseRelicUri(Layout storage t, string memory uri) internal {
        t.baseRelicUri = uri;
    }

    /**
     * @dev returns the current token data associated with a token id and data position.
     * @param relicId - the relic to obtain data from
     * @param loc - the position in the token's data storage
     */
    function _tokenData(Layout storage t, uint256 relicId, uint256 loc) internal view returns (uint256) {
        return t.tokenData[relicId][loc];
    }

    /**
     * @dev updates the current token data associated with a token id and data position.
     * @param relicId - the relic to obtain data from
     * @param loc - the position in the token's data storage
     * @param bits - the data to be assigned to a tokens data storage
     */
    function _setTokenData(Layout storage t, uint256 relicId, uint256 loc, uint256 bits) internal {
        t.tokenData[relicId][loc] = bits;
    }
}