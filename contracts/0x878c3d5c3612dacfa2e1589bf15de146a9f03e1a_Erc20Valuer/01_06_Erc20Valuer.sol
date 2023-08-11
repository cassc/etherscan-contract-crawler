// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';
import { IERC20Metadata } from '@solidstate/contracts/token/ERC20/metadata/IERC20Metadata.sol';

import { IValuer } from '../valuers/IValuer.sol';

contract Erc20Valuer is IValuer {
    function getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue) {
        return _getVaultValue(vault, asset, unitPrice);
    }

    function getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue) {
        return _getAssetValue(amount, asset, unitPrice);
    }

    function getAssetBreakdown(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (AssetValue memory) {
        (uint min, uint max) = _getVaultValue(vault, asset, unitPrice);
        uint balance = IERC20(asset).balanceOf(vault);
        AssetBreakDown[] memory ab = new AssetBreakDown[](1);
        ab[0] = AssetBreakDown(asset, balance, min, max);
        return AssetValue(asset, min, max, ab);
    }

    function getAssetActive(
        address vault,
        address asset
    ) external view returns (bool) {
        return IERC20(asset).balanceOf(vault) > 0;
    }

    function _getVaultValue(
        address vault,
        address asset,
        int256 unitPrice
    ) internal view returns (uint256 minValue, uint256 maxValue) {
        uint balance = IERC20(asset).balanceOf(vault);
        return _getAssetValue(balance, asset, unitPrice);
    }

    function _getAssetValue(
        uint amount,
        address asset,
        int256 unitPrice
    ) internal view returns (uint256 minValue, uint256 maxValue) {
        uint decimals = IERC20Metadata(asset).decimals();
        uint value = (uint(unitPrice) * amount) / (10 ** decimals);
        return (value, value);
    }
}