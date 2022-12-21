// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./lib/Assets.sol";

contract AssetHandler {

    using Assets for Assets.Map;

    Assets.Map assets;

    function _setAsset(Assets.Key key, string memory assetTicker, Assets.AssetType assetType) internal virtual returns (bool) {
        return assets.set(key, Assets.Asset(assetTicker, assetType));
    }

    function _removeAsset(Assets.Key key) internal virtual returns (bool) {
        return assets.remove(key);
    }

    function assetsLength() public view returns (uint256) {
        return assets.length();
    }

    function getAssetAt(uint256 index) public view returns (Assets.Key, Assets.Asset memory) {
        return assets.at(index);
    }

    function getAsset(Assets.Key key) public view returns (Assets.Asset memory) {
        return assets.get(key);
    }

    function _approveAsset(address spender, uint256 amount, Assets.Key assetKey) internal returns (bool) {
        return IERC20(Assets.Key.unwrap(assetKey)).approve(spender, amount);
    }

    function _transferAsset(address recipient, uint256 amount, Assets.Key assetKey) internal {
        Assets.Asset memory asset = assets.get(assetKey);
        require(asset.assetType == Assets.AssetType.ERC20, "AssetHandler: only ERC20 assets supported");
        IERC20(Assets.Key.unwrap(assetKey)).transfer(recipient, amount);
    }

    function _transferAssetFrom(address sender, address recipient, uint256 amount, Assets.Key assetKey) internal {
        Assets.Asset memory asset = assets.get(assetKey);
        require(asset.assetType == Assets.AssetType.ERC20, "AssetHandler: only ERC20 assets supported");
        IERC20(Assets.Key.unwrap(assetKey)).transferFrom(sender, recipient, amount);
    }

}