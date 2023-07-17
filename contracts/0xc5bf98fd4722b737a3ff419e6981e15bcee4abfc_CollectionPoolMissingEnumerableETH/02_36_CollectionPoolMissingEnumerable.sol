// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";

/**
 * @title An NFT/Token pool for an NFT that does not implement ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolMissingEnumerable is CollectionPool {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721, uint256 numNFTs) internal view override returns (uint256[] memory nftIds) {
        uint256 lastIndex = idSet.length();
        if (numNFTs > 0 && numNFTs <= lastIndex) {
            nftIds = new uint256[](numNFTs);
            // NOTE: We start from last index to first index to save on gas when we eventully _withdrawNFTs on results
            lastIndex = lastIndex - 1;

            for (uint256 i; i < numNFTs;) {
                uint256 nftId = idSet.at(lastIndex);
                nftIds[i] = nftId;

                unchecked {
                    --lastIndex;
                    ++i;
                }
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() public view override returns (uint256[] memory nftIds) {
        nftIds = idSet.values();
    }

    /// @inheritdoc CollectionPool
    function _depositNFTs(address from, uint256[] calldata nftIds) internal override {
        // transfer NFTs to this pool and update set
        IERC721 _nft = nft();
        uint256 length = nftIds.length;
        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(from, address(this), nftId);
            idSet.add(nftId);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _depositNFTsNotification(uint256[] calldata nftIds) internal override {
        uint256 length = nftIds.length;
        for (uint256 i; i < length;) {
            idSet.add(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal override {
        IERC721 _nft = nft();

        // Send NFTs to given addres and update valid set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs;) {
            _nft.safeTransferFrom(address(this), to, nftIds[i]);
            idSet.remove(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ICollectionPool
    function NFTsCount() external view returns (uint256) {
        return idSet.length();
    }
}