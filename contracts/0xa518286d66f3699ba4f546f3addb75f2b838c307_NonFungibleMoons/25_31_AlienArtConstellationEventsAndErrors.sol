// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title AlienArtConstellationEventsAndErrors
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
contract AlienArtConstellationEventsAndErrors {
    // Event to be emitted when swap constellations occurs
    event SwapConstellations(
        address indexed owner,
        uint256 indexed moon1,
        uint256 indexed moon2,
        uint256 newConstellationForMoon1,
        uint256 newConstellationForMoon2
    );

    // Set moon address errors
    error MoonAddressAlreadySet();

    // Mint errors
    error MsgSenderNotMoonAddress();

    // Swap constellations errors
    error SwapMoonsOwnerMustBeMsgSender();

    // Uri errors
    error InvalidConstellationIndex();
}