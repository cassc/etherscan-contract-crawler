// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import './IRenovaCommandDeckBase.sol';

/// @title IRenovaCommandDeck
/// @author Victor Ionescu
/// @notice See {IRenovaCommandDeckBase}
/// @dev Deployed on the main chain.
interface IRenovaCommandDeck is IRenovaCommandDeckBase {
    struct ItemMintSpec {
        /// @param hashverseItemIds Hashverse Item IDs for items to mint
        uint256[] hashverseItemIds;
        /// @param rootId ID of the Merkle Root.
        bytes32 rootId;
        /// @param proof The Merkle proof.
        bytes32[] proof;
    }

    /// @notice Emitted when a new Merkle root is added for item minting.
    /// @param rootId The ID of the Root.
    /// @param root The Root.
    event UploadItemMerkleRoot(bytes32 rootId, bytes32 root);

    /// @notice Emitted when a player has minted through a Merkle Root.
    /// @param rootId The ID of the Root.
    /// @param player The address of the Player that minted.
    event MintItems(bytes32 rootId, address player);

    /// @notice Initializer function.
    /// @param renovaAvatar The address of the Avatar contract.
    /// @param renovaItem The address of the Item contract.
    /// @param hashflowRouter The address of the Hashflow Router.
    /// @param questOwner The address of the Quest Owner.
    function initialize(
        address renovaAvatar,
        address renovaItem,
        address hashflowRouter,
        address questOwner
    ) external;

    /// @notice Returns the Merkle root associated with a root ID.
    /// @param rootId The root ID.
    function itemMerkleRoots(bytes32 rootId) external view returns (bytes32);

    /// @notice Uploads a Merkle root for minting items.
    /// @param rootId The root ID.
    /// @param root The Merkle root.
    function uploadItemMerkleRoot(bytes32 rootId, bytes32 root) external;

    /// @notice Mints a set of items via Merkle root.
    /// @param tokenOwner The wallet receiving the item.
    /// @param mintSpecs Collection of Merkle proofs for items to mint.
    function mintItems(
        address tokenOwner,
        ItemMintSpec[] calldata mintSpecs
    ) external;

    /// @notice Mints an item via admin privileges.
    /// @param tokenOwner The wallet receiving the item.
    /// @param hashverseItemId The Hashverse Item ID of the minted item.
    function mintItemAdmin(
        address tokenOwner,
        uint256 hashverseItemId
    ) external;
}