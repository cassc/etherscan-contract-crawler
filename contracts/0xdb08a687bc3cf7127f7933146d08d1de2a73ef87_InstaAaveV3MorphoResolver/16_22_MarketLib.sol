// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.6;

// import {IAToken} from "../interfaces/aave/IAToken.sol";
import { IPool } from "./aave-v3-core/interfaces/IPool.sol";

import { Types } from "./Types.sol";
// import {Events} from "./Events.sol";
// import {Errors} from "./Errors.sol";
// import {ReserveDataLib} from "./ReserveDataLib.sol";

import { Math } from "./math/Math.sol";
import { WadRayMath } from "./math/WadRayMath.sol";
import { PercentageMath } from "./math/PercentageMath.sol";

// import {SafeCast} from "@openzeppelin/contracts/utils/math/SafeCast.sol";

import { DataTypes } from "./aave-v3-core/protocol/libraries/types/DataTypes.sol";
import { ReserveConfiguration } from "./aave-v3-core/protocol/libraries/configration/ReserveConfiguration.sol";

/// @title MarketLib
/// @author Morpho Labs
/// @custom:contact [email protected]
/// @notice Library used to ease market reads and writes.
library MarketLib {
    using Math for uint256;
    // using SafeCast for uint256;
    using WadRayMath for uint256;
    using MarketLib for Types.Market;

    // using ReserveDataLib for DataTypes.ReserveData;
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;

    /// @notice Returns whether the `market` is created or not.
    function isCreated(Types.Market memory market) internal pure returns (bool) {
        return market.aToken != address(0);
    }

    /// @notice Returns whether supply is paused on `market` or not.
    function isSupplyPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isSupplyPaused;
    }

    /// @notice Returns whether supply collateral is paused on `market` or not.
    function isSupplyCollateralPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isSupplyCollateralPaused;
    }

    /// @notice Returns whether borrow is paused on `market` or not.
    function isBorrowPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isBorrowPaused;
    }

    /// @notice Returns whether repay is paused on `market` or not.
    function isRepayPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isRepayPaused;
    }

    /// @notice Returns whether withdraw is paused on `market` or not.
    function isWithdrawPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isWithdrawPaused;
    }

    /// @notice Returns whether withdraw collateral is paused on `market` or not.
    function isWithdrawCollateralPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isWithdrawCollateralPaused;
    }

    /// @notice Returns whether liquidate collateral is paused on `market` or not.
    function isLiquidateCollateralPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isLiquidateCollateralPaused;
    }

    /// @notice Returns whether liquidate borrow is paused on `market` or not.
    function isLiquidateBorrowPaused(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isLiquidateBorrowPaused;
    }

    /// @notice Returns whether the `market` is deprecated or not.
    function isDeprecated(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isDeprecated;
    }

    /// @notice Returns whether the peer-to-peer is disabled on `market` or not.
    function isP2PDisabled(Types.Market memory market) internal pure returns (bool) {
        return market.pauseStatuses.isP2PDisabled;
    }

    // /// @notice Sets the `market` as `isCollateral` on Morpho.
    // function setAssetIsCollateral(Types.Market storage market, bool isCollateral) internal {
    //     market.isCollateral = isCollateral;

    //     emit Events.IsCollateralSet(market.underlying, isCollateral);
    // }

    // /// @notice Sets the `market` supply pause status as `isPaused` on Morpho.
    // function setIsSupplyPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isSupplyPaused = isPaused;

    //     emit Events.IsSupplyPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` supply collateral pause status as `isPaused` on Morpho.
    // function setIsSupplyCollateralPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isSupplyCollateralPaused = isPaused;

    //     emit Events.IsSupplyCollateralPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` borrow pause status as `isPaused` on Morpho.
    // function setIsBorrowPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isBorrowPaused = isPaused;

    //     emit Events.IsBorrowPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` repay pause status as `isPaused` on Morpho.
    // function setIsRepayPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isRepayPaused = isPaused;

    //     emit Events.IsRepayPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` withdraw pause status as `isPaused` on Morpho.
    // function setIsWithdrawPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isWithdrawPaused = isPaused;

    //     emit Events.IsWithdrawPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` withdraw collateral pause status as `isPaused` on Morpho.
    // function setIsWithdrawCollateralPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isWithdrawCollateralPaused = isPaused;

    //     emit Events.IsWithdrawCollateralPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` liquidate collateral pause status as `isPaused` on Morpho.
    // function setIsLiquidateCollateralPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isLiquidateCollateralPaused = isPaused;

    //     emit Events.IsLiquidateCollateralPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` liquidate borrow pause status as `isPaused` on Morpho.
    // function setIsLiquidateBorrowPaused(Types.Market storage market, bool isPaused) internal {
    //     market.pauseStatuses.isLiquidateBorrowPaused = isPaused;

    //     emit Events.IsLiquidateBorrowPausedSet(market.underlying, isPaused);
    // }

    // /// @notice Sets the `market` as `deprecated` on Morpho.
    // function setIsDeprecated(Types.Market storage market, bool deprecated) internal {
    //     market.pauseStatuses.isDeprecated = deprecated;

    //     emit Events.IsDeprecatedSet(market.underlying, deprecated);
    // }

    // /// @notice Sets the `market` peer-to-peer as `p2pDisabled` on Morpho.
    // function setIsP2PDisabled(Types.Market storage market, bool p2pDisabled) internal {
    //     market.pauseStatuses.isP2PDisabled = p2pDisabled;

    //     emit Events.IsP2PDisabledSet(market.underlying, p2pDisabled);
    // }

    // /// @notice Sets the `market` peer-to-peer reserve factor to `reserveFactor`.
    // function setReserveFactor(Types.Market storage market, uint16 reserveFactor) internal {
    //     if (reserveFactor > PercentageMath.PERCENTAGE_FACTOR) revert Errors.ExceedsMaxBasisPoints();
    //     market.reserveFactor = reserveFactor;

    //     emit Events.ReserveFactorSet(market.underlying, reserveFactor);
    // }

    // /// @notice Sets the `market` peer-to-peer index cursor to `p2pIndexCursor`.
    // function setP2PIndexCursor(Types.Market storage market, uint16 p2pIndexCursor) internal {
    //     if (p2pIndexCursor > PercentageMath.PERCENTAGE_FACTOR) revert Errors.ExceedsMaxBasisPoints();
    //     market.p2pIndexCursor = p2pIndexCursor;

    //     emit Events.P2PIndexCursorSet(market.underlying, p2pIndexCursor);
    // }

    // /// @notice Sets the `market` indexes to `indexes`.
    // function setIndexes(Types.Market storage market, Types.Indexes256 memory indexes) internal {
    //     market.indexes.supply.poolIndex = indexes.supply.poolIndex.toUint128();
    //     market.indexes.supply.p2pIndex = indexes.supply.p2pIndex.toUint128();
    //     market.indexes.borrow.poolIndex = indexes.borrow.poolIndex.toUint128();
    //     market.indexes.borrow.p2pIndex = indexes.borrow.p2pIndex.toUint128();
    //     market.lastUpdateTimestamp = uint32(block.timestamp);
    //     emit Events.IndexesUpdated(
    //         market.underlying,
    //         indexes.supply.poolIndex,
    //         indexes.supply.p2pIndex,
    //         indexes.borrow.poolIndex,
    //         indexes.borrow.p2pIndex
    //     );
    // }

    // /// @notice Returns the supply indexes of `market`.
    // function getSupplyIndexes(Types.Market storage market)
    //     internal
    //     view
    //     returns (Types.MarketSideIndexes256 memory supplyIndexes)
    // {
    //     supplyIndexes.poolIndex = uint256(market.indexes.supply.poolIndex);
    //     supplyIndexes.p2pIndex = uint256(market.indexes.supply.p2pIndex);
    // }

    // /// @notice Returns the borrow indexes of `market`.
    // function getBorrowIndexes(Types.Market storage market)
    //     internal
    //     view
    //     returns (Types.MarketSideIndexes256 memory borrowIndexes)
    // {
    //     borrowIndexes.poolIndex = uint256(market.indexes.borrow.poolIndex);
    //     borrowIndexes.p2pIndex = uint256(market.indexes.borrow.p2pIndex);
    // }

    // /// @notice Returns the indexes of `market`.
    // function getIndexes(Types.Market storage market) internal view returns (Types.Indexes256 memory indexes) {
    //     indexes.supply = getSupplyIndexes(market);
    //     indexes.borrow = getBorrowIndexes(market);
    // }

    /// @notice Returns the proportion of idle supply in `market` over the total peer-to-peer amount in supply.
    function getProportionIdle(Types.Market memory market) internal pure returns (uint256) {
        uint256 idleSupply = market.idleSupply;
        if (idleSupply == 0) return 0;

        uint256 totalP2PSupplied = market.deltas.supply.scaledP2PTotal.rayMul(market.indexes.supply.p2pIndex);
        if (totalP2PSupplied == 0) return 0;

        // We take the minimum to handle the case where the proportion is rounded to greater than 1.
        return Math.min(idleSupply.rayDivUp(totalP2PSupplied), WadRayMath.RAY);
    }

    // /// @notice Increases the idle supply if the supply cap is reached in a breaking repay, and returns a new toSupply amount.
    // /// @param market The market storage.
    // /// @param underlying The underlying address.
    // /// @param amount The amount to repay. (by supplying on pool)
    // /// @param reserve The reserve data for the market.
    // /// @return The amount to supply to stay below the supply cap and the amount the idle supply was increased by.
    // function increaseIdle(
    //     Types.Market storage market,
    //     address underlying,
    //     uint256 amount,
    //     DataTypes.ReserveData memory reserve,
    //     Types.Indexes256 memory indexes
    // ) internal returns (uint256, uint256) {
    //     uint256 supplyCap = reserve.configuration.getSupplyCap() * (10 ** reserve.configuration.getDecimals());
    //     if (supplyCap == 0) return (amount, 0);

    //     uint256 suppliable = supplyCap.zeroFloorSub(
    //         (IAToken(market.aToken).scaledTotalSupply() + reserve.getAccruedToTreasury(indexes)).rayMul(
    //             indexes.supply.poolIndex
    //         )
    //     );
    //     if (amount <= suppliable) return (amount, 0);

    //     uint256 idleSupplyIncrease = amount - suppliable;
    //     uint256 newIdleSupply = market.idleSupply + idleSupplyIncrease;

    //     market.idleSupply = newIdleSupply;

    //     emit Events.IdleSupplyUpdated(underlying, newIdleSupply);

    //     return (suppliable, idleSupplyIncrease);
    // }

    // /// @notice Decreases the idle supply.
    // /// @param market The market storage.
    // /// @param underlying The underlying address.
    // /// @param amount The amount to borrow.
    // /// @return The amount left to process and the processed amount.
    // function decreaseIdle(Types.Market storage market, address underlying, uint256 amount)
    //     internal
    //     returns (uint256, uint256)
    // {
    //     if (amount == 0) return (0, 0);

    //     uint256 idleSupply = market.idleSupply;
    //     if (idleSupply == 0) return (amount, 0);

    //     uint256 matchedIdle = Math.min(idleSupply, amount); // In underlying.
    //     uint256 newIdleSupply = idleSupply.zeroFloorSub(matchedIdle);
    //     market.idleSupply = newIdleSupply;

    //     emit Events.IdleSupplyUpdated(underlying, newIdleSupply);

    //     return (amount - matchedIdle, matchedIdle);
    // }

    /// @notice Calculates the total quantity of underlyings truly supplied peer-to-peer on the given market.
    /// @param indexes The current indexes.
    /// @return The total peer-to-peer supply (total peer-to-peer supply - supply delta - idle supply).
    function trueP2PSupply(Types.Market memory market, Types.Indexes256 memory indexes)
        internal
        pure
        returns (uint256)
    {
        Types.MarketSideDelta memory supplyDelta = market.deltas.supply;
        return
            supplyDelta
                .scaledP2PTotal
                .rayMul(indexes.supply.p2pIndex)
                .zeroFloorSub(supplyDelta.scaledDelta.rayMul(indexes.supply.poolIndex))
                .zeroFloorSub(market.idleSupply);
    }

    /// @notice Calculates the total quantity of underlyings truly borrowed peer-to-peer on the given market.
    /// @param indexes The current indexes.
    /// @return The total peer-to-peer borrow (total peer-to-peer borrow - borrow delta).
    function trueP2PBorrow(Types.Market memory market, Types.Indexes256 memory indexes)
        internal
        pure
        returns (uint256)
    {
        Types.MarketSideDelta memory borrowDelta = market.deltas.borrow;
        return
            borrowDelta.scaledP2PTotal.rayMul(indexes.borrow.p2pIndex).zeroFloorSub(
                borrowDelta.scaledDelta.rayMul(indexes.borrow.poolIndex)
            );
    }

    // /// @notice Calculates & deducts the reserve fee to repay from the given amount, updating the total peer-to-peer amount.
    // /// @param amount The amount to repay (in underlying).
    // /// @param indexes The current indexes.
    // /// @return The new amount left to process (in underlying).
    // function repayFee(Types.Market storage market, uint256 amount, Types.Indexes256 memory indexes)
    //     internal
    //     returns (uint256)
    // {
    //     if (amount == 0) return 0;

    //     Types.Deltas storage deltas = market.deltas;
    //     uint256 feeToRepay = Math.min(amount, market.trueP2PBorrow(indexes).zeroFloorSub(market.trueP2PSupply(indexes)));

    //     if (feeToRepay == 0) return amount;

    //     deltas.borrow.scaledP2PTotal =
    //         deltas.borrow.scaledP2PTotal.zeroFloorSub(feeToRepay.rayDivDown(indexes.borrow.p2pIndex)); // P2PTotalsUpdated emitted in `decreaseP2P`.

    //     return amount - feeToRepay;
    // }
}