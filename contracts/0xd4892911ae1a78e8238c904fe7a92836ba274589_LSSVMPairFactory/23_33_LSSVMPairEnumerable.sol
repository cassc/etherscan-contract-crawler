// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "./imports/IERC721Enumerable.sol";
import {IERC721} from "./imports/IERC721.sol";
import {LSSVMRouter} from "./LSSVMRouter.sol";
import {LSSVMPair} from "./LSSVMPair.sol";
import {ILSSVMPairFactoryLike} from "./ILSSVMPairFactoryLike.sol";
import {IAzimuth} from "./imports/IAzimuth.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    @author Adapted for Urbitex by ~dosdel-falrud based on original work by boredGenius and 0xmons
 */
abstract contract LSSVMPairEnumerable is LSSVMPair {
    /// @inheritdoc LSSVMPair
    function _sendAnyNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256 numNFTs
    ) internal override {
        // Send NFTs to recipient
        // (we know NFT implements IERC721Enumerable so we just iterate)
        uint256 lastIndex = _nft.balanceOf(address(this)) - 1;
        for (uint256 i = 0; i < numNFTs; ) {
            uint256 nftId = IERC721Enumerable(address(_nft))
                .tokenOfOwnerByIndex(address(this), lastIndex);
            _nft.safeTransferFrom(address(this), nftRecipient, nftId);

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal override {
        // Send NFTs to recipient
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(address(this), nftRecipient, nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc LSSVMPair
    function getAllHeldIds() external view override returns (uint256[] memory) {
        IERC721 _ecliptic = ecliptic();
        uint256 numNFTs = _ecliptic.balanceOf(address(this));
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs; ) {
            ids[i] = IERC721Enumerable(address(_ecliptic)).tokenOfOwnerByIndex(
                address(this),
                i
            );

            unchecked {
                ++i;
            }
        }
        return ids;
    }
    /** 
        @dev This function acts as the primary check to ensure that only valid stars can enter a pool.
        Any NFTs sent via unsafe transfer are ignored by the protocol, even if they're valid stars.
    */
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes memory
    ) public virtual returns (bytes4) {

        IAzimuth _azimuth = azimuth();
                
        require(_azimuth.getPointSize(uint32(id)) == IAzimuth.Size.Star, "must be a star");
        require(_azimuth.getSpawnCount(uint32(id)) == 0, "has spawned planets");
        require(_azimuth.getSpawnProxy(uint32(id)) != 0x1111111111111111111111111111111111111111, "proxy set");

        return this.onERC721Received.selector;
    }

    /// @inheritdoc LSSVMPair
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds)
        external
        override
        onlyOwner
    {
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            a.safeTransferFrom(address(this), msg.sender, nftIds[i]);

            unchecked {
                ++i;
            }
        }
        emit NFTWithdrawal();
    }
}