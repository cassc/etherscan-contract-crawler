// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "../interfaces/ITransferProxy.sol";
import "../libraries/AssetLib.sol";

/**
 * @title RecrowTransfer
 * @notice Manages asset transfer logic
 */
abstract contract RecrowTransfer is ERC721Holder, ERC1155Holder {
    using SafeERC20 for IERC20;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transferred(AssetLib.AssetData asset, address from, address to);

    /*//////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidAmount();
    error InvalidAssetClass();
    error InsufficientETH();
    error CannotSendETH();

    /*//////////////////////////////////////////////////////////////
                            TRANSFER LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfer an asset according to their class.
     * @dev Will revert if `assetClass` is not allowed.
     * @param asset The asset that will be transferred.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     */
    function _transfer(
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) internal {
        if (asset.assetType.assetClass == AssetLib.ETH_ASSET_CLASS) {
            _ethTransfer(from, to, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.ERC20_ASSET_CLASS) {
            (address token, ) = AssetLib.decodeAssetTypeData(asset.assetType);
            _erc20safeTransferFrom(token, from, to, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.ERC721_ASSET_CLASS) {
            (address token, uint256 tokenId) = AssetLib.decodeAssetTypeData(
                asset.assetType
            );
            if (asset.value != 1) revert InvalidAmount();
            _erc721safeTransferFrom(token, from, to, tokenId);
        } else if (asset.assetType.assetClass == AssetLib.ERC1155_ASSET_CLASS) {
            (address token, uint256 tokenId) = AssetLib.decodeAssetTypeData(
                asset.assetType
            );
            _erc1155safeTransferFrom(token, from, to, tokenId, asset.value);
        } else if (asset.assetType.assetClass == AssetLib.PROXY_ASSET_CLASS) {
            (address proxy, ) = AssetLib.decodeAssetTypeData(asset.assetType);
            _transferProxyTransfer(proxy, asset, from, to);
        } else {
            revert InvalidAssetClass();
        }

        emit Transferred(asset, from, to);
    }

    /**
     * @notice Transfers ETH.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param value Amount of ETH to send.
     */
    function _ethTransfer(
        address from,
        address to,
        uint256 value
    ) private {
        if (from != address(this)) {
            if (msg.value < value) revert InsufficientETH();
        }
        if (to != address(this)) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = to.call{ value: value }("");
            if (!success) revert CannotSendETH();
        }
    }

    /**
     * @notice Transfers ERC20.
     * @param token Address of the ERC20 token.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param value Amount of ERC20 to send.
     */
    function _erc20safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) private {
        if (from == address(this)) {
            IERC20(token).safeTransfer(to, value);
        } else {
            IERC20(token).safeTransferFrom(from, to, value);
        }
    }

    /**
     * @notice Transfers ERC721.
     * @param token Address of the token.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param tokenId Token id of the ERC721 token.
     */
    function _erc721safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 tokenId
    ) private {
        IERC721(token).safeTransferFrom(from, to, tokenId);
    }

    /**
     * @notice Transfers ERC1155.
     * @param token Address of the token.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     * @param id Token id of the ERC1155 token.
     * @param value Amount of ERC1155 to send.
     */
    function _erc1155safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 value
    ) private {
        IERC1155(token).safeTransferFrom(from, to, id, value, "");
    }

    /**
     * @notice Transfers asset via a proxy.
     * @param proxy Address of the proxy.
     * @param asset The asset that will be transferred.
     * @param from Address that will send the asset.
     * @param to Address that will receive the asset.
     */
    function _transferProxyTransfer(
        address proxy,
        AssetLib.AssetData memory asset,
        address from,
        address to
    ) private {
        ITransferProxy(proxy).transfer(asset, from, to);
    }
}