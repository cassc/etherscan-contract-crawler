// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.18;

import "../interfaces/IRMRKExtended.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/access/Ownable.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/extension/soulbound/IERC6454.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/nestable/IERC6059.sol";

error InvalidNumberOfAssets();
error InvalidNumberOfDestinationIds();
error InvalidNumberOfToAddresses();
error NotOwnerOrContributor();

contract MetaFactory is ERC721Holder {
    event NewRmrkNft(uint256 tokenId, address indexed rmrkCollectionContract);
    event NewRmrkAsset(
        uint256 assetId,
        uint256 tokenId,
        address indexed rmrkCollectionContract
    );

    modifier onlyCollectionOwner(address collection) {
        _checkCollectionOwner(collection);
        _;
    }

    /**
     * @notice Creates a new asset entry and adds it to the token
     * @param collection The address of the RMRK collection
     * @param tokenId The ID of the token
     * @param asset The asset to set
     */
    function createNewAssetAndAddToToken(
        address collection,
        uint256 tokenId,
        string calldata asset
    ) public onlyCollectionOwner(collection) {
        _createNewAssetAndAddToToken(collection, tokenId, asset);
    }

    function _createNewAssetAndAddToToken(
        address collection,
        uint256 tokenId,
        string calldata asset
    ) private {
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));

        // Resource is autoaccepted if it is a RMRK implementation and it is the first asset, or it is owned by the caller
        IRMRKExtended(collection).addAssetToToken(
            tokenId,
            assetId,
            0 // 0 is the default value as we don't overwrite anything
        );

        emit NewRmrkAsset(assetId, tokenId, collection);
    }

    function mintTokenWithAsset(
        address collection,
        string calldata asset,
        address to
    ) public payable onlyCollectionOwner(collection) {
        uint256 tokenId = IRMRKExtended(collection).mint{value: msg.value}(
            to,
            1
        );

        _createNewAssetAndAddToToken(collection, tokenId, asset);
        emit NewRmrkNft(tokenId, collection);
    }

    // @dev If collection uses soulbound, only the first asset is accepted
    function mintTokenWithMultipleAssets(
        address collection,
        string[] calldata assets,
        address to
    ) public payable onlyCollectionOwner(collection) {
        bool isSoulbound = IERC165(collection).supportsInterface(
            type(IERC6454).interfaceId
        );
        uint256 tokenId;
        if (isSoulbound) {
            // Mint directly to destination
            tokenId = IRMRKExtended(collection).mint{value: msg.value}(to, 1);
        } else {
            // Mint to this contract first, so all assets are auto accepted
            tokenId = IRMRKExtended(collection).mint{value: msg.value}(
                address(this),
                1
            );
        }

        for (uint256 i; i < assets.length; ) {
            _createNewAssetAndAddToToken(collection, tokenId, assets[i]);
            unchecked {
                ++i;
            }
        }

        if (!isSoulbound) {
            // Transfer to destination
            IERC721(collection).safeTransferFrom(address(this), to, tokenId);
        }
        emit NewRmrkNft(tokenId, collection);
    }

    function mintMultipleTokensWithSameAsset(
        address collection,
        string calldata asset,
        address[] calldata toAddresses,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));
        uint256 individualValue = msg.value / amount;
        for (uint256 i; i < amount; ) {
            uint256 tokenId = IRMRKExtended(collection).mint{
                value: individualValue
            }(toAddresses[i], 1);
            // Resource is autoaccepted if it is a RMRK implementation because it is the first asset
            IRMRKExtended(collection).addAssetToToken(
                tokenId,
                assetId,
                0 // 0 is the default value as we don't overwrite anything
            );
            emit NewRmrkNft(tokenId, collection);
            unchecked {
                ++i;
            }
        }
    }

    function mintMultipleTokensWithSameAssetSameAddress(
        address collection,
        string calldata asset,
        address toAddress,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));
        uint256 firstTokenId = IRMRKExtended(collection).mint{value: msg.value}(
            toAddress,
            amount
        );
        _mintMultipleTokensWithExistingAssetSameAddress(
            collection,
            assetId,
            amount,
            firstTokenId
        );
    }

    function mintMultipleTokensWithExistingAssetSameAddress(
        address collection,
        uint64 assetId,
        address toAddress,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        uint256 firstTokenId = IRMRKExtended(collection).mint{value: msg.value}(
            toAddress,
            amount
        );
        _mintMultipleTokensWithExistingAssetSameAddress(
            collection,
            assetId,
            amount,
            firstTokenId
        );
    }

    function _mintMultipleTokensWithExistingAssetSameAddress(
        address collection,
        uint64 assetId,
        uint256 amount,
        uint256 firstTokenId
    ) private {
        for (uint256 i; i < amount; ) {
            // Resource is autoaccepted if it is a RMRK implementation because it is the first asset
            IRMRKExtended(collection).addAssetToToken(
                firstTokenId + i,
                assetId,
                0 // 0 is the default value as we don't overwrite anything
            );
            emit NewRmrkNft(firstTokenId + i, collection);
            unchecked {
                ++i;
            }
        }
    }

    function mintMultipleTokensWithDifferentAsset(
        address collection,
        string[] calldata assets,
        address[] calldata toAddresses,
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        if (assets.length != amount) {
            revert InvalidNumberOfAssets();
        }
        if (toAddresses.length != amount) {
            revert InvalidNumberOfToAddresses();
        }

        uint256 individualValue = msg.value / amount;
        for (uint256 i; i < amount; ) {
            uint256 tokenId = IRMRKExtended(collection).mint{
                value: individualValue
            }(toAddresses[i], 1);
            _createNewAssetAndAddToToken(collection, tokenId, assets[i]);
            emit NewRmrkNft(tokenId, collection);
            unchecked {
                ++i;
            }
        }
    }

    function nestMintTokenWithAsset(
        address collection,
        string calldata asset,
        address to,
        uint256 destinationId
    ) public payable onlyCollectionOwner(collection) {
        _nestMintTokenWithAsset(
            collection,
            asset,
            to,
            destinationId,
            msg.value
        );
    }

    // @dev If collection uses soulbound, only the first asset is accepted
    function nestMintTokenWithMultipleAssets(
        address collection,
        string[] calldata assets,
        address to,
        uint256 destinationId
    ) public payable onlyCollectionOwner(collection) {
        bool isSoulbound = IERC165(collection).supportsInterface(
            type(IERC6454).interfaceId
        );
        uint256 tokenId;
        if (isSoulbound) {
            // Mint directly to destination
            tokenId = IRMRKExtended(collection).nestMint{value: msg.value}(
                to,
                1,
                destinationId
            );
        } else {
            // Mint to this contract first, so all assets are auto accepted
            tokenId = IRMRKExtended(collection).mint{value: msg.value}(
                address(this),
                1
            );
        }

        for (uint256 i; i < assets.length; ) {
            _createNewAssetAndAddToToken(collection, tokenId, assets[i]);
            unchecked {
                ++i;
            }
        }

        if (!isSoulbound) {
            // Transfer to destination
            IERC6059(collection).nestTransferFrom(
                address(this),
                to,
                tokenId,
                destinationId,
                ""
            );
        }
        emit NewRmrkNft(tokenId, collection);
    }

    function _nestMintTokenWithAsset(
        address collection,
        string calldata asset,
        address to,
        uint256 destinationId,
        uint256 individualValue
    ) private {
        uint256 tokenId = IRMRKExtended(collection).nestMint{
            value: individualValue
        }(to, 1, destinationId);

        _createNewAssetAndAddToToken(collection, tokenId, asset);
        emit NewRmrkNft(tokenId, collection);
    }

    function nestMintMultipleTokensWithSameAsset(
        address collection,
        string calldata asset, // Same asset for all tokens
        address to, // We expect the destination collection to be the same for all tokens
        uint256[] calldata destinationIds, // We expect the destination collection to be different for all tokens
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        if (destinationIds.length != amount) {
            revert InvalidNumberOfDestinationIds();
        }

        uint256 individualValue = msg.value / amount;
        uint64 assetId = uint64(IRMRKExtended(collection).addAssetEntry(asset));
        for (uint256 i; i < amount; ) {
            uint256 tokenId = IRMRKExtended(collection).nestMint{
                value: individualValue
            }(to, 1, destinationIds[i]);
            // Resource is autoaccepted if it is a RMRK implementation because it is the first asset
            IRMRKExtended(collection).addAssetToToken(
                tokenId,
                assetId,
                0 // 0 is the default value as we don't overwrite anything
            );
            emit NewRmrkNft(tokenId, collection);
            unchecked {
                ++i;
            }
        }
    }

    function nestMintMultipleTokensWithDifferentAsset(
        address collection,
        string[] calldata assets, // One asset per token
        address to, // We expect the destination collection to be the same for all tokens
        uint256[] calldata destinationIds, // We expect the destination collection to be different for all tokens
        uint256 amount
    ) public payable onlyCollectionOwner(collection) {
        if (destinationIds.length != amount) {
            revert InvalidNumberOfDestinationIds();
        }
        if (assets.length != amount) {
            revert InvalidNumberOfAssets();
        }

        uint256 individualValue = msg.value / amount;
        for (uint256 i; i < amount; ) {
            _nestMintTokenWithAsset(
                collection,
                assets[i],
                to,
                destinationIds[i],
                individualValue
            );
            unchecked {
                ++i;
            }
        }
    }

    function _checkCollectionOwner(address collection) internal view {
        if (
            Ownable(collection).owner() != msg.sender &&
            !Ownable(collection).isContributor(msg.sender)
        ) {
            revert NotOwnerOrContributor();
        }
    }
}