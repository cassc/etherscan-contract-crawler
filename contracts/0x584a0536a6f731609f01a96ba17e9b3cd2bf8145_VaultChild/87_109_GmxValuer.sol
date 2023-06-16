// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IValuer } from '../valuers/IValuer.sol';
import { Registry } from '../registry/Registry.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { IGmxPositionRouter } from '../interfaces/IGmxPositionRouter.sol';
import { IGmxRouter } from '../interfaces/IGmxRouter.sol';
import { IGmxVault } from '../interfaces/IGmxVault.sol';

import { GmxStoredData } from '../lib/GmxStoredData.sol';
import { GmxHelpers } from '../lib/GmxHelpers.sol';

import { Constants } from '../lib/Constants.sol';

contract GmxValuer is IValuer {
    function getGmxPositions(
        address valioVault
    ) external view returns (GmxStoredData.GMXPositionData[] memory) {
        return GmxStoredData.getStoredPositions(valioVault);
    }

    function getVaultValue(
        address valioVault,
        address gmxVault, // asset
        int256 // unitPrice
    ) external view returns (uint256 minValue, uint256 maxValue) {
        return _getVaultValue(valioVault, gmxVault, 0);
    }

    function getAssetBreakdown(
        address vault,
        address asset,
        int256 unitPrice
    ) external view returns (AssetValue memory) {
        AssetBreakDown[] memory ab = new AssetBreakDown[](10);
        (uint min, uint max) = _getVaultValue(vault, asset, unitPrice);
        ab[0] = AssetBreakDown(asset, 0, min, max);
        return AssetValue(asset, min, max, ab);
    }

    function getAssetValue(
        uint,
        address,
        int256
    ) external pure returns (uint256, uint) {
        revert('Cannot value individual units');
    }

    function _getVaultValue(
        address valioVault,
        address gmxVault, // asset
        int256 // unitPrice ignored for now as value returned in USD
    ) internal view returns (uint256 minValue, uint256 maxValue) {
        // Check for value locked in increaseRequests
        (
            uint minOrderValue,
            uint maxOrderValue
        ) = _calculateOutstandingRequestValue(valioVault);

        GmxStoredData.GMXPositionData[] memory positions = GmxStoredData
            .getStoredPositions(valioVault);
        (minValue, maxValue) = _calculateAllPositionsValue(
            valioVault,
            IGmxVault(gmxVault),
            positions
        );
        minValue += minOrderValue;
        maxValue += maxOrderValue;
    }

    function _calculateAllPositionsValue(
        address valioVault,
        IGmxVault gmxVault,
        GmxStoredData.GMXPositionData[] memory positions
    ) internal view returns (uint256 minValue, uint maxValue) {
        for (uint i = 0; i < positions.length; i++) {
            (uint posMinValue, uint posMaxValue) = _calculatePositionValue(
                valioVault,
                gmxVault,
                positions[i]
            );
            minValue += posMinValue;
            maxValue += posMaxValue;
        }
    }

    function _calculatePositionValue(
        address valioVault,
        IGmxVault gmxVault,
        GmxStoredData.GMXPositionData memory keyData
    ) internal view returns (uint256 minValue, uint maxValue) {
        (
            uint256 size,
            uint collateral,
            ,
            uint entryFundingRate,
            ,
            ,
            ,

        ) = IGmxVault(gmxVault).getPosition(
                valioVault,
                keyData._collateralToken,
                keyData._indexToken,
                keyData._isLong
            );

        if (size == 0) {
            return (0, 0);
        }

        bool hasProfit;
        uint delta;
        (hasProfit, delta) = IGmxVault(gmxVault).getPositionDelta(
            valioVault,
            keyData._collateralToken,
            keyData._indexToken,
            keyData._isLong
        );

        if (!hasProfit && delta > collateral) {
            return (0, 0);
        }

        maxValue = hasProfit ? collateral + delta : collateral - delta;

        uint fundingFee = IGmxVault(gmxVault).getFundingFee(
            keyData._collateralToken,
            size,
            entryFundingRate
        );

        uint totalFees = fundingFee + IGmxVault(gmxVault).getPositionFee(size);
        uint precisionAdjustment = (IGmxVault(gmxVault).PRICE_PRECISION() /
            Constants.VAULT_PRECISION);
        if (totalFees > maxValue) {
            maxValue = maxValue / precisionAdjustment;
            minValue = 0;
        } else {
            minValue = (maxValue - totalFees) / precisionAdjustment;
            maxValue = maxValue / precisionAdjustment;
        }
    }

    function _calculateOutstandingRequestValue(
        address vault
    ) internal view returns (uint minValue, uint maxValue) {
        Registry registry = VaultBaseExternal(vault).registry();
        // increasePositionsIndex is incremented everytime an account creates a request, it's never decremented
        // All requests are executed in order so we search backwards and aggregate all value
        // until we find a request that has been executed
        uint increaseRequestIndex = registry
            .gmxConfig()
            .positionRouter()
            .increasePositionsIndex(vault);

        if (increaseRequestIndex == 0) {
            return (0, 0);
        }

        for (uint i = increaseRequestIndex; i > 0; i--) {
            bytes32 key = registry.gmxConfig().positionRouter().getRequestKey(
                vault,
                i
            );
            (address account, address inputToken, uint amountIn) = GmxHelpers
                .getIncreasePositionRequestsData(
                    registry.gmxConfig().positionRouter(),
                    key
                );

            if (account == address(0)) {
                break;
            }

            (uint minAssetValue, uint maxAssetValue) = registry
                .accountant()
                .assetValue(inputToken, amountIn);
            minValue += minAssetValue;
            maxValue += maxAssetValue;
        }
    }
}