// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.18;

import "@rmrk-team/evm-contracts/contracts/implementations/premint/RMRKEquippableImplPreMint.sol";
import "@rmrk-team/evm-contracts/contracts/RMRK/extension/soulbound/RMRKSoulbound.sol";

contract RMRKEquippablePreMintSoulboundMP is
    RMRKSoulbound,
    RMRKEquippableImplPreMint
{
    constructor(
        string memory name_,
        string memory symbol_,
        string memory collectionMetadata_,
        string memory tokenURI_,
        InitData memory data
    )
        RMRKEquippableImplPreMint(
            name_,
            symbol_,
            collectionMetadata_,
            tokenURI_,
            data
        )
    {}

    /**
     * @inheritdoc IERC165
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(RMRKAbstractEquippableImpl, RMRKSoulbound)
        returns (bool)
    {
        return
            interfaceId == type(IERC165).interfaceId ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC6059).interfaceId ||
            interfaceId == type(IERC5773).interfaceId ||
            interfaceId == type(IERC6220).interfaceId ||
            interfaceId == type(IERC6454).interfaceId ||
            interfaceId == RMRK_INTERFACE;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(RMRKAbstractEquippableImpl, RMRKSoulbound) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _afterAddAssetToToken(
        uint256 tokenId,
        uint64 assetId,
        uint64 replacesAssetWithId
    ) internal virtual override {
        super._afterAddAssetToToken(tokenId, assetId, replacesAssetWithId);
        // This relies on no other auto accept mechanism being in place.
        // We auto accept the first ever asset or any asset added by the token owner.
        // This is done to allow a meta factory to mint, add assets and accept them in one transaction.
        // The first accept auto accept is specially relevant since this token is soulbound, it cannot be minted to factory and later transferred, and there is no simpler way to force the asset to be accepted.
        if (
            _activeAssets[tokenId].length == 0 ||
            _msgSender() == ownerOf(tokenId)
        ) {
            _acceptAsset(tokenId, _pendingAssets[tokenId].length - 1, assetId);
        }
    }
}