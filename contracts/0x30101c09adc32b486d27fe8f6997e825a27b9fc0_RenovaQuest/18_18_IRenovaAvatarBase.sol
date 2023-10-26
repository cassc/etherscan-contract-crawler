// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '../external/erc/IERC4906Upgradeable.sol';

/// @title IRenovaAvatarBase
/// @author Victor Ionescu
/**
@notice NFT base contract holding Avatars. In order to play in the Hashverse players
have to mint an Avatar. Avatars are soul-bound (non-transferrable) and represent
the entirety of a player's journey in the Hashverse.

Avatars can be minted on multiple chains. Minting new Avatars can only happen on the
main chain. Once an Avatar is minted on the main chain, it can be minted on satellite
chains by making cross-chain calls.

Players have to mint Avatars on each chain if they want to enter a quest that is
occurring on that particular chain.
*/
interface IRenovaAvatarBase is IERC4906Upgradeable {
    enum RenovaFaction {
        RESISTANCE,
        SOLUS
    }

    /// @notice Emitted when an Avatar is minted.
    /// @param player The owner of the Avatar.
    /// @param tokenId The Token ID minted.
    /// @param faction The faction of the Avatar.
    /// @param characterId The character ID minted.
    event Mint(
        address indexed player,
        uint256 tokenId,
        RenovaFaction faction,
        uint256 characterId
    );

    /// @notice Emitted when the Custom Metadata URI is updated.
    /// @param uri The new URI.
    event UpdateCustomURI(string uri);

    /// @notice Returns the faction of a player.
    /// @param player The player.
    /// @return The faction.
    function factions(address player) external view returns (RenovaFaction);

    /// @notice Returns the character ID of a player.
    /// @param player The player.
    /// @return The character ID.
    function characterIds(address player) external view returns (uint256);

    /// @notice Returns the token ID of a player.
    /// @param player The player.
    /// @return The token ID.
    function tokenIds(address player) external view returns (uint256);

    /// @notice Sets a custom base URI for the token metadata.
    /// @param customBaseURI The new Custom URI.
    function setCustomBaseURI(string memory customBaseURI) external;

    /// @notice Emits a refresh metadata event for a token.
    /// @param tokenId The ID of the token.
    function refreshMetadata(uint256 tokenId) external;

    /// @notice Emits a refresh metadata event for all tokens.
    function refreshAllMetadata() external;
}