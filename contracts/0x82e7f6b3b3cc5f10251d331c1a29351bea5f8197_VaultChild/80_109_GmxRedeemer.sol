// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import { IERC20 } from '@solidstate/contracts/interfaces/IERC20.sol';

import { Registry } from '../registry/Registry.sol';
import { VaultBaseExternal } from '../vault-base/VaultBaseExternal.sol';
import { IRedeemer } from '../redeemers/IRedeemer.sol';
import { IGmxPositionRouter } from '../interfaces/IGmxPositionRouter.sol';
import { IGmxRouter } from '../interfaces/IGmxRouter.sol';
import { IGmxVault } from '../interfaces/IGmxVault.sol';
import { GmxStoredData } from '../lib/GmxStoredData.sol';
import { GmxHelpers } from '../lib/GmxHelpers.sol';
import { Constants } from '../lib/Constants.sol';

import 'hardhat/console.sol';

contract GmxRedeemer is IRedeemer {
    bool public constant hasPreWithdraw = true;

    function withdraw(
        address gmxVault,
        address withdrawer,
        uint portion
    ) external payable {}

    function preWithdraw(
        address gmxVault,
        address withdrawer,
        uint portion
    ) external payable override {
        // We need to cancel any pending `increasePosition` orders as the collateral for those
        // is held by gmx with the order (returned if/when the order is cancelled).
        // This should be exceedingly rare but we need to handle it.
        // Decided to revert for now.
        _checkIfHasUnexcutedRequest();

        GmxStoredData.GMXPositionData[] memory positions = GmxStoredData
            .getStoredPositions(address(this));

        for (uint256 i = 0; i < positions.length; i++) {
            GmxStoredData.GMXPositionData memory keyData = positions[i];
            _processPosition(gmxVault, withdrawer, portion, keyData);
        }
    }

    function _processPosition(
        address gmxVault,
        address withdrawer,
        uint portion,
        GmxStoredData.GMXPositionData memory keyData
    ) internal {
        (
            uint256 size,
            uint collateral,
            ,
            uint entryFundingRate,
            ,
            ,
            ,

        ) = IGmxVault(gmxVault).getPosition(
                address(this),
                keyData._collateralToken,
                keyData._indexToken,
                keyData._isLong
            );

        if (size == 0) {
            return;
        }

        if (portion == Constants.PORTION_DIVISOR) {
            _closeEntirePositionAndReturnProceedsToVault(
                gmxVault,
                keyData,
                size,
                collateral
            );
            return;
        }

        uint sizePortion = (size * portion) / Constants.PORTION_DIVISOR;
        uint collateralPortion = (collateral * portion) /
            Constants.PORTION_DIVISOR;

        // Gmx has a variety of complex conditions that need to pass to reduce a position by a portion
        // Most of the time the position will be reduced by the partial amount successfully
        // If it fails we close the entire position to the vault and issue the withdrawer their portion of the proceeds
        // This is not the most elegant solution but it's the safest.
        try
            IGmxVault(gmxVault).decreasePosition(
                address(this),
                keyData._collateralToken,
                keyData._indexToken,
                collateralPortion -
                    _feesToDeductFromCollateral(
                        gmxVault,
                        keyData,
                        entryFundingRate,
                        size,
                        sizePortion,
                        collateralPortion
                    ), // collateralDelta
                sizePortion, // sizeDelta
                keyData._isLong,
                withdrawer
            )
        returns (uint amountOut) {
            VaultBaseExternal(address(this)).addActiveAsset(
                keyData._isLong ? keyData._indexToken : keyData._collateralToken
            );
            VaultBaseExternal(address(this)).registry().emitEvent();
            emit PreWithdraw(
                gmxVault,
                withdrawer,
                keyData._isLong
                    ? keyData._indexToken
                    : keyData._collateralToken,
                amountOut
            );
        } catch {
            _closeEntirePositionAndReturnProceedsToVault(
                gmxVault,
                keyData,
                size,
                collateral
            );
        }
    }

    function _closeEntirePositionAndReturnProceedsToVault(
        address gmxVault,
        GmxStoredData.GMXPositionData memory keyData,
        uint size,
        uint collateral
    ) internal {
        address returnAsset = keyData._isLong
            ? keyData._indexToken
            : keyData._collateralToken;

        uint amountOut = IGmxVault(gmxVault).decreasePosition(
            address(this),
            keyData._collateralToken,
            keyData._indexToken,
            collateral, // collateralDelta
            size, // sizeDelta
            keyData._isLong,
            address(this) // return the proceeds to the vault
        );

        VaultBaseExternal(address(this)).addActiveAsset(returnAsset);
        VaultBaseExternal(address(this)).registry().emitEvent();
        emit PreWithdraw(
            gmxVault,
            address(this),
            keyData._isLong ? keyData._indexToken : keyData._collateralToken,
            amountOut
        );
    }

    function _checkIfHasUnexcutedRequest() internal view {
        Registry registry = VaultBaseExternal(address(this)).registry();
        // increasePositionsIndex is incremented everytime an account creates a request, it's never decremented
        // All requests are executed in order so if the last request payload still exists in the mapping
        // there is still an open request
        uint increasePositionsIndex = registry
            .gmxConfig()
            .positionRouter()
            .increasePositionsIndex(address(this));

        bytes32 key = registry.gmxConfig().positionRouter().getRequestKey(
            address(this),
            increasePositionsIndex
        );
        (address account, , ) = GmxHelpers.getIncreasePositionRequestsData(
            registry.gmxConfig().positionRouter(),
            key
        );
        if (account == address(this)) {
            revert('open gmx request');
        }
    }

    // When reducing a position in gmx if the amount the user will receive from the reduction is less than the fees,
    // the fees are deducted from the collateral :(
    // We need to make sure that this doesn't happen because the remaining collateral should stay with the vault
    // If this is the case we deduct the fees from the collateral delta and return the rest to the user
    function _feesToDeductFromCollateral(
        address gmxVault,
        GmxStoredData.GMXPositionData memory keyData,
        uint entryFundingRate,
        uint size,
        uint sizePortion,
        uint collateralPortion
    ) internal view returns (uint feesToDeductFromCollateral) {
        uint fees = IGmxVault(gmxVault).getFundingFee(
            keyData._collateralToken,
            sizePortion,
            entryFundingRate
        ) + IGmxVault(gmxVault).getPositionFee(sizePortion);

        uint256 usdOut;

        (bool hasProfit, uint delta) = IGmxVault(gmxVault).getPositionDelta(
            address(this),
            keyData._collateralToken,
            keyData._indexToken,
            keyData._isLong
        );

        // get the proportional change in pnl
        uint adjustedDelta = (sizePortion * delta) / size;

        if (hasProfit && adjustedDelta > 0) {
            usdOut = adjustedDelta;
        }

        usdOut = usdOut + collateralPortion;

        if (fees > usdOut) {
            feesToDeductFromCollateral = fees;
        }
    }
}