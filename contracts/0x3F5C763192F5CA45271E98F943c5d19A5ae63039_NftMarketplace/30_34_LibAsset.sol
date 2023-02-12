// SPDX-License-Identifier: MIT
pragma solidity >=0.8.16;
library LibAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 constant public COLLECTION = bytes4(keccak256("COLLECTION"));
    bytes4 constant public CRYPTO_PUNK = bytes4(keccak256("CRYPTO_PUNK"));
    bytes4 constant public CRYPTO_KITTY = bytes4(keccak256("CRYPTO_KITTY"));
    bytes32 constant private ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );
    bytes32 constant private ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,bytes data)AssetType(bytes4 assetClass,bytes data)"
    );
    struct AssetType {
        bytes4 assetClass;      // asset class (erc20, 721, etc)
        bytes data;             // (address, uint256, bool) = (contract address, tokenId - only NFTs, allow all from collection - only NFTs)
                                // if allow all = true, ignore tokenId
    }
    struct Asset {
        AssetType assetType;
        bytes data;             // (uint256, uint256) = value, minimumBid
                                //      SELL ORDER:
                                //          MAKE: (the amount for sale, 0)
                                //          TAKE: (buy now price, min bid value), if decreasing price auction, then (start price, ending price)
                                //      BUY  ORDER:
                                //          MAKE: (amount offered must >= min bid value, 0)
                                //          TAKE: (must match sell order make, 0)
    }
    function hash(AssetType calldata assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ASSET_TYPE_TYPEHASH,
            assetType.assetClass,
            keccak256(assetType.data)
        ));
    }
    function hash(Asset calldata asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ASSET_TYPEHASH,
            hash(asset.assetType),
            keccak256(asset.data)
        ));
    }
    function hash(Asset[] calldata assets) internal pure returns (bytes32) {
        bytes32[] memory assetHashes = new bytes32[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            assetHashes[i] = hash(assets[i]);
        }
        return keccak256(abi.encodePacked(assetHashes));
    }
    function isSingularNft(
        Asset[] calldata assets
    ) internal pure returns (bool) {
        if (assets.length == 1 && assets[0].assetType.assetClass == ERC721_ASSET_CLASS) {
            return true;
        } else {
            return false;
        }
    }
    function isOnlyFungible(
        Asset[] calldata assets
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (assets[i].assetType.assetClass != ERC20_ASSET_CLASS &&
                assets[i].assetType.assetClass != ETH_ASSET_CLASS) {
                return false;
            }
        }

        return true;
    }
}