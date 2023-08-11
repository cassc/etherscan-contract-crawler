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
 * @title  MintStorage
 * @author slvrfn
 * @notice Library responsible for loading the associated "layout" from storage, and setting/retrieving
 *         the internal fields.
 */
library MintStorage {
    using MintStorage for MintStorage.Layout;

    bytes32 internal constant STORAGE_SLOT = keccak256("genesis.libraries.storage.MintStorage");

    struct Layout {
        uint216 tokenIdCounter;
        uint16 mintPhase;
        uint16 maxTokensPerAddress;
        mapping(address => uint256) tokensMintedPerAddress;
        mapping(uint256 => uint256) phaseFee;
    }

    /**
     * @notice Obtains the MintStorage layout from storage.
     * @dev    layout is stored at the chosen STORAGE_SLOT.
     */
    function layout() internal pure returns (Layout storage s) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }

    /**
     * @dev Returns the current token id counter.
     */
    function _tokenIdCounter(Layout storage m) internal view returns (uint216) {
        return m.tokenIdCounter;
    }

    /**
     * @dev Obtains the current tokenIdCounter, incrementing it afterwards for later use.
     */
    function _postincTokenIdCounter(Layout storage m) internal returns (uint216) {
        // token id is current state of the counter
        uint216 tokenId = m.tokenIdCounter;
        // increment tokenId counter
        // save some gas
        unchecked {
            ++m.tokenIdCounter;
        }
        return tokenId;
    }

    /**
     * @dev Returns the current mint phase.
     */
    function _mintPhase(Layout storage m) internal view returns (uint16) {
        return m.mintPhase;
    }

    /**
     * @dev   Updates the current mint phase.
     * @param newPhase - the new mint phase.
     */
    function _setMintPhase(Layout storage m, uint16 newPhase) internal {
        m.mintPhase = newPhase;
    }

    /**
     * @dev Returns the current max tokens per address.
     */
    function _maxTokensPerAddress(Layout storage m) internal view returns (uint16) {
        return m.maxTokensPerAddress;
    }

    /**
     * @dev   Updates the current max tokens per address.
     * @param newMax - the new max.
     */
    function _setMaxTokensPerAddress(Layout storage m, uint16 newMax) internal {
        m.maxTokensPerAddress = newMax;
    }

    /**
     * @dev Returns the current number tokens minted by an address.
     * @param addr - the address to check.
     */
    function _tokensMintedPerAddress(Layout storage m, address addr) internal view returns (uint256) {
        return m.tokensMintedPerAddress[addr];
    }

    /**
     * @dev   Updates the current max tokens per address.
     * @param addr - the address to get incremented.
     * @param qty - how much to increment by.
     */
    function _incTokensMintedPerAddress(Layout storage m, address addr, uint256 qty) internal {
        // save some gas
        unchecked {
            m.tokensMintedPerAddress[addr] += qty;
        }
    }

    /**
     * @dev   Returns the current fee associated with a mint phase
     * @param phase - the phase to check.
     */
    function _phaseFee(Layout storage m, uint256 phase) internal view returns (uint256) {
        return m.phaseFee[phase];
    }

    /**
     * @dev   Returns the current fee associated with a mint phase
     * @param phase - the phase to have its fee updated.
     * @param newFee - the new mint fee.
     */
    function _setPhaseFee(Layout storage m, uint256 phase, uint256 newFee) internal {
        m.phaseFee[phase] = newFee;
    }
}