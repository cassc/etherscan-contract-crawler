pragma solidity ^0.8.4;


/// @dev Interface of the asset proxy's assetData.
// The asset proxies take an ABI encoded `bytes assetData` as argument.
// This argument is ABI encoded as one of the methods of this interface.
interface IAssetData {

    /// @dev Function signature for encoding ERC20 assetData.
    /// @param tokenAddress Address of ERC20Token contract.
    function ERC20Token(address tokenAddress)
        external;

    /// @dev Function signature for encoding ERC721 assetData.
    /// @param tokenAddress Address of ERC721 token contract.
    /// @param tokenId Id of ERC721 token to be transferred.
    function ERC721Token(
        address tokenAddress,
        uint256 tokenId
    )
        external;

    /// @dev Function signature for encoding ERC1155 assetData.
    /// @param tokenAddress Address of ERC1155 token contract.
    /// @param tokenIds Array of ids of tokens to be transferred.
    /// @param values Array of values that correspond to each token id to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param callbackData Extra data to be passed to receiver's `onERC1155Received` callback function.
    function ERC1155Assets(
        address tokenAddress,
        uint256[] calldata tokenIds,
        uint256[] calldata values,
        bytes calldata callbackData
    )
        external;

    /// @dev Function signature for encoding MultiAsset assetData.
    /// @param values Array of amounts that correspond to each asset to be transferred.
    ///        Note that each value will be multiplied by the amount being filled in the order before transferring.
    /// @param nestedAssetData Array of assetData fields that will be be dispatched to their correspnding AssetProxy contract.
    function MultiAsset(
        uint256[] calldata values,
        bytes[] calldata nestedAssetData
    )
        external;
}