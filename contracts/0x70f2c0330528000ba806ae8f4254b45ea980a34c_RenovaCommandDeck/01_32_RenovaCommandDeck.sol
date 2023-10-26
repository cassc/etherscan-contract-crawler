// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import '../interfaces/core/IRenovaCommandDeck.sol';
import '../interfaces/nft/IRenovaItem.sol';

import './RenovaCommandDeckBase.sol';

/// @title RenovaCommandDeck
/// @author Victor Ionescu
/// @notice See {IRenovaCommandDeck}
contract RenovaCommandDeck is IRenovaCommandDeck, RenovaCommandDeckBase {
    /// @inheritdoc IRenovaCommandDeck
    mapping(bytes32 => bytes32) public itemMerkleRoots;

    mapping(bytes32 => mapping(address => bool)) internal _mintedItems;

    /// @dev Reserved for future upgrades.
    uint256[16] private __gap;

    /// @inheritdoc IRenovaCommandDeck
    function initialize(
        address _renovaAvatar,
        address _renovaItem,
        address _hashflowRouter,
        address _questOwner
    ) external override initializer {
        __RenovaCommandDeckBase_init(
            _renovaAvatar,
            _renovaItem,
            _hashflowRouter,
            _questOwner
        );
    }

    /// @inheritdoc IRenovaCommandDeck
    function mintItems(
        address tokenOwner,
        ItemMintSpec[] calldata mintSpecs
    ) external override {
        require(
            mintSpecs.length > 0,
            'RenovaCommandDeck::minItems No mint specs provided.'
        );
        for (uint256 specIdx = 0; specIdx < mintSpecs.length; specIdx++) {
            bytes32 rootId = mintSpecs[specIdx].rootId;
            uint256[] memory hashverseItemIds = mintSpecs[specIdx]
                .hashverseItemIds;

            require(
                !_mintedItems[rootId][tokenOwner],
                'RenovaCommandDeck::mintItems Already minted.'
            );

            bytes32 root = itemMerkleRoots[rootId];
            require(
                root != bytes32(0),
                'RenovaCommandDeck::mintItems Root not found.'
            );

            bytes32 leaf = keccak256(
                abi.encodePacked(tokenOwner, hashverseItemIds)
            );

            require(
                MerkleProofUpgradeable.verifyCalldata(
                    mintSpecs[specIdx].proof,
                    root,
                    leaf
                ),
                'RenovaCommandDeck::mintItems Proof invalid.'
            );

            _mintedItems[rootId][tokenOwner] = true;

            for (uint256 i = 0; i < hashverseItemIds.length; i++) {
                _mintItem(tokenOwner, hashverseItemIds[i]);
            }
        }
    }

    /// @inheritdoc IRenovaCommandDeck
    function uploadItemMerkleRoot(
        bytes32 rootId,
        bytes32 root
    ) external override {
        require(
            _msgSender() == questOwner,
            'RenovaCommandDeck::uploadItemMerkleRoot Sender must be Quest Owner.'
        );
        require(
            itemMerkleRoots[rootId] == bytes32(0),
            'RenovaCommandDeck::uploadItemMerkleRoot Root already defined.'
        );

        itemMerkleRoots[rootId] = root;

        emit UploadItemMerkleRoot(rootId, root);
    }

    /// @inheritdoc IRenovaCommandDeck
    function mintItemAdmin(
        address tokenOwner,
        uint256 hashverseItemId
    ) external override onlyOwner {
        _mintItem(tokenOwner, hashverseItemId);
    }

    /// @notice Mints an Item to a specific owner.
    /// @param tokenOwner The owner of the Item.
    /// @param hashverseItemId The Hashverse Item ID.
    function _mintItem(address tokenOwner, uint256 hashverseItemId) internal {
        require(
            renovaItem != address(0),
            'RenovaCommandDeck::_mintItem RenovaItem not set.'
        );

        IRenovaItem(renovaItem).mint(tokenOwner, hashverseItemId);
    }
}