// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title MoonNFTEventsAndErrors
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
contract MoonNFTEventsAndErrors {
    // Event to be emitted when alien art address is updated
    event AlienArtAddressUpdated(
        uint256 indexed tokenId,
        address indexed alienArtAddress
    );

    // Event to be emitted when mint with referrer occurs
    event MintedWithReferrer(
        // Referrer address
        address indexed referrerAddress,
        // Referrer token
        uint256 indexed referrerToken,
        // Minter address
        address indexed minterAddress,
        // Token id of first token minted during this mint
        uint256 mintStartTokenId,
        // Amount of tokens minted
        uint256 amount,
        // Value paid to referrer
        uint256 referrerPayout,
        // Value paid to referred
        uint256 referredPayout
    );

    // Event to emitted when moon regeneration occurs
    event MoonRegenerated(
        address indexed moonOwner,
        uint256 indexed tokenId,
        bytes32 indexed newMoonSeed,
        bytes32 previousMoonSeed,
        uint8 regenerationsUsed
    );

    // Mint errors
    error MaxSupplyReached();
    error WrongEtherAmount();

    // Regeneration errors
    error NoRegenerationsRemaining();

    // Alien art token-level errors
    error AlienArtContractFailedValidation();
    error OwnerNotMsgSender();
}