// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./interfaces/ITransferExecutor.sol";
import "./lib/LibTransfer.sol";
import "./lib/LibPart.sol";

abstract contract TransferExecutor is
    Initializable,
    ITransferExecutor
{
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using LibTransfer for address;

    function __TransferExecutor_init_unchained() internal {}

    function transfer(
        LibAsset.Asset memory asset,
        address from,
        address to
    ) internal override {
        if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            to.transferEth(asset.value);
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            address token = abi.decode(asset.assetType.data, (address));
            SafeERC20Upgradeable.safeTransferFrom(IERC20Upgradeable(token), from, to, asset.value);
        } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            require(asset.value == 1, "erc721 value error");
            IERC721Upgradeable(asset.token).safeTransferFrom(from, to, asset.tokenId, "");
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            IERC1155Upgradeable(asset.token).safeTransferFrom(
                from,
                to,
                asset.tokenId,
                asset.value,
                ""
            );
        } else {
            revert("asetClass is invalid");
        }
    }
}