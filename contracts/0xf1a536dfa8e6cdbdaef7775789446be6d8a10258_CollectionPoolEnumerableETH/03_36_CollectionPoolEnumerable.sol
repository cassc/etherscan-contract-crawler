// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool for an NFT that implements ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolEnumerable is CollectionPool {
    using BitMaps for BitMaps.BitMap;

    // NFT IDs that match our filter are maintained in this BitMap and counted in idLength
    BitMaps.BitMap private idMap;
    uint256 private idLength;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs)
        internal
        view
        override
        returns (uint256[] memory nftIds)
    {
        uint256 userBalance = _nft.balanceOf(address(this));
        uint256 j;

        if (numNFTs > 0 && numNFTs <= userBalance) {
            nftIds = new uint256[](numNFTs);
            for (uint256 i; i < numNFTs;) {
                // index will be out of bounds if numNFTs > balance
                uint256 nftId = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(address(this), j);

                // make sure it's a legal (filtered) ID
                if (idMap.get(nftId)) {
                    nftIds[i] = nftId;
                    unchecked {
                        ++i;
                    }
                }

                unchecked {
                    ++j;
                }
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() public view override returns (uint256[] memory nftIds) {
        return _selectArbitraryNFTs(nft(), idLength);
    }

    /// @inheritdoc CollectionPool
    function _depositNFTs(address from, uint256[] calldata nftIds) internal override {
        // transfer NFTs to this pool and update map/size
        IERC721 _nft = nft();
        uint256 length = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(from, address(this), nftId);
            if (!idMap.get(nftId)) {
                idMap.set(nftId);
                ++_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc CollectionPool
    function _depositNFTsNotification(uint256[] calldata nftIds) internal override {
        uint256 length = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            if (!idMap.get(nftId)) {
                idMap.set(nftId);
                ++_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc CollectionPool
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal override {
        // Send NFTs to given address, update map and count
        IERC721 _nft = nft();
        uint256 numNFTs = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < numNFTs;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(address(this), to, nftId);
            // Remove from id map
            if (idMap.get(nftId)) {
                idMap.unset(nftId);
                --_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc ICollectionPool
    function NFTsCount() external view returns (uint256) {
        return idLength;
    }
}