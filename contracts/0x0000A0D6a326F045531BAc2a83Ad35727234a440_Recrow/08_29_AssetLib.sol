// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @title AssetLib
 * @notice Library for handling Asset data structure
 */
library AssetLib {
    /*//////////////////////////////////////////////////////////////
                        ASSET CLASS CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /// @notice Bytes4 representations of allowed asset (token) classes.
    bytes4 public constant ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 public constant ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 public constant ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 public constant ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));
    bytes4 public constant PROXY_ASSET_CLASS = bytes4(keccak256("PROXY"));

    /// @notice Asset typehash for EIP712 compatibility.
    bytes32 public constant ASSET_TYPE_TYPEHASH =
        keccak256("AssetType(bytes4 assetClass,bytes data)");
    bytes32 public constant ASSET_TYPEHASH =
        keccak256(
            "AssetData(AssetType assetType,uint256 value,address recipient)AssetType(bytes4 assetClass,bytes data)"
        );

    /*//////////////////////////////////////////////////////////////
                          ASSET DATA STRUCTURE
    //////////////////////////////////////////////////////////////*/

    /// @notice Struct holding the asset's class and details
    struct AssetType {
        // Asset (token) classification
        bytes4 assetClass;
        // Additional asset information (ex: contract address, tokenId)
        bytes data;
    }

    /// @notice Struct holding the data for an asset transfer
    struct AssetData {
        // Specification of the asset
        AssetType assetType;
        // Amount of asset to transfer
        uint256 value;
        // Transfer reecipient of the asset
        address recipient;
    }

    /*//////////////////////////////////////////////////////////////
                            DECODE LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Decode additional data associated with the asset.
     * @param assetType AssetType of the asset.
     */
    function decodeAssetTypeData(AssetType memory assetType)
        internal
        pure
        returns (address, uint256)
    {
        if (
            assetType.assetClass == AssetLib.ERC721_ASSET_CLASS ||
            assetType.assetClass == AssetLib.ERC1155_ASSET_CLASS
        ) {
            (address token, uint256 tokenId) = abi.decode(
                assetType.data,
                (address, uint256)
            );
            return (token, tokenId);
        } else if (assetType.assetClass == AssetLib.ERC20_ASSET_CLASS) {
            address token = abi.decode(assetType.data, (address));
            return (token, 0);
        } else if (assetType.assetClass == AssetLib.PROXY_ASSET_CLASS) {
            address proxy = abi.decode(assetType.data, (address));
            return (proxy, 0);
        }
        return (address(0), 0);
    }

    /*//////////////////////////////////////////////////////////////
                             HASH FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice EIP712-compatible hash of AssetType.
     * @param assetType AssetType of the asset.
     * @return hash of the assetType.
     */
    function hash(AssetType calldata assetType)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPE_TYPEHASH,
                    assetType.assetClass,
                    keccak256(assetType.data)
                )
            );
    }

    /**
     * @notice EIP712-compatible hash of AssetData.
     * @param asset AssetData of the asset.
     * @return hash of the asset.
     */
    function hash(AssetData calldata asset) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ASSET_TYPEHASH,
                    hash(asset.assetType),
                    asset.value,
                    asset.recipient
                )
            );
    }

    /**
     * @notice EIP712-compatible hash packing of AssetData.
     * @param assets AssetData assets to pack.
     * @return hash of the assets.
     */
    function packAssets(AssetData[] calldata assets)
        internal
        pure
        returns (bytes32)
    {
        bytes32[] memory assetHashes = new bytes32[](assets.length);
        for (uint256 i = 0; i < assets.length; i++) {
            assetHashes[i] = hash(assets[i]);
        }
        return keccak256(abi.encodePacked(assetHashes));
    }
}