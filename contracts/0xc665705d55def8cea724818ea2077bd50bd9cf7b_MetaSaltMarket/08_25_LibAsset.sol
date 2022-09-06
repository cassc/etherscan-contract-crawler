// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

library LibAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));    
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC721_LAZY_ASSET_CLASS = bytes4(keccak256("ERC721_LAZY")); 
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 constant public ERC1155_LAZY_ASSET_CLASS = bytes4(keccak256("ERC1155_LAZY")); 
    
    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );

    bytes32 constant ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPE_TYPEHASH,
                assetType.assetClass,
                keccak256(assetType.data)
            ));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPEHASH,
                hash(asset.assetType),
                asset.value
            ));
    }

    function validation(Asset memory asset) internal pure {
        require(asset.assetType.assetClass == ETH_ASSET_CLASS || asset.assetType.assetClass == ETH_ASSET_CLASS || asset.assetType.assetClass == ETH_ASSET_CLASS, "Not Supported Asset");
    }
}