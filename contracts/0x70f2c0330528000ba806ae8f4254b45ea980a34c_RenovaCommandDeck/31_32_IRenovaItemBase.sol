// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import '../external/erc/IERC4906Upgradeable.sol';

/// @title IRenovaItemBase
/// @author Victor Ionescu
/**
@notice NFT base contract for Hashverse Items. Each token has an associated Hashverse Item ID.
This ID is the unique representation of the Item in the Hashverse. All tokens with the same
Hashverse Item ID represent the same type of item (e.g. a weapon with damage 50).

The link between the Hashverse Item ID and the item characteristics is stored off-chain and
made public via the metadata file. Metadata can change as players complete quests. Each
change in metadata will be followed by an ERC4906 event emission.

Items can only be minted on the main chain, and can be bridged arbitrarily between chains.
 */
interface IRenovaItemBase is IERC4906Upgradeable {
    /// @notice Emitted when an item is minted.
    /// @param player The player who owns the item.
    /// @param tokenId The token ID.
    /// @param hashverseItemId The Hashverse Item ID.
    event Mint(
        address indexed player,
        uint256 tokenId,
        uint256 hashverseItemId
    );

    /// @notice Emitted when the Custom Metadata URI is updated.
    /// @param uri The new URI.
    event UpdateCustomURI(string uri);

    /// @notice Emitted when an item is bridged out of the current chain.
    /// @param player The player.
    /// @param tokenId The Token ID.
    /// @param hashverseItemId The Hashverse Item ID.
    /// @param dstWormholeChainId The Wormhole Chain ID of the chain the item is being bridged to.
    /// @param sequence The Wormhole sequence number.
    event XChainBridgeOut(
        address indexed player,
        uint256 tokenId,
        uint256 hashverseItemId,
        uint16 dstWormholeChainId,
        uint256 sequence,
        uint256 relayerFee
    );

    /// @notice Emitted when an item was bridged into the current chain.
    /// @param player The player.
    /// @param tokenId The Token ID.
    /// @param hashverseItemId The Hashverse Item ID.
    /// @param srcWormholeChainId The Wormhole Chain ID of the chain the item is being bridged from.
    event XChainBridgeIn(
        address indexed player,
        uint256 tokenId,
        uint256 hashverseItemId,
        uint16 srcWormholeChainId
    );

    /// @notice Bridges an item into the chain via Wormhole.
    /// @param vaa The Wormhole VAA.
    function wormholeBridgeIn(bytes memory vaa) external;

    /// @notice Bridges an item out of the chain via Wormhole.
    /// @param tokenId The Token ID.
    /// @param dstWormholeChainId The Wormhole Chain ID of the chain the item is being bridged to.
    function wormholeBridgeOut(
        uint256 tokenId,
        uint16 dstWormholeChainId,
        uint256 wormholeMessageFee
    ) external payable;

    /// @notice Sets the default royalty for the Item collection.
    /// @param receiver The receiver of royalties.
    /// @param feeNumerator The numerator of the fraction denoting the royalty percentage.
    function setDefaultRoyalty(address receiver, uint96 feeNumerator) external;

    /// @notice Sets a custom base URI for the token metadata.
    /// @param customBaseURI The new Custom URI.
    function setCustomBaseURI(string memory customBaseURI) external;

    /// @notice Emits a refresh metadata event for a token.
    /// @param tokenId The ID of the token.
    function refreshMetadata(uint256 tokenId) external;

    /// @notice Emits a refresh metadata event for all tokens.
    function refreshAllMetadata() external;
}