// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.17;

import "../interfaces/DexAggregatorInterface.sol";
import "../interfaces/OpenLevInterface.sol";
import "../IOPBorrowing.sol";
import "../OPBorrowingLib.sol";
import "../libraries/DexData.sol";
import "../libraries/Utils.sol";

contract BorrowingHelper {
    using DexData for bytes;

    constructor() {}

    enum BorrowingStatus {
        HEALTHY, // Do nothing
        UPDATING_PRICE, // Need update price
        WAITING, // Waiting for 1 min before liquidate
        LIQUIDATING, // Can liquidate
        NOP // No position
    }

    struct BorrowingStatVars {
        uint256 collateral;
        uint256 lastUpdateTime;
        BorrowingStatus status;
    }

    struct CollateralVars {
        uint256 collateral;
        uint256 borrowing;
        uint256 collateralRatio;
    }

    uint internal constant RATIO_DENOMINATOR = 10000;

    function collateralRatios(
        IOPBorrowing borrowing,
        uint16[] calldata marketIds,
        address[] calldata borrowers,
        bool[] calldata collateralIndexes
    ) external view returns (uint[] memory results) {
        results = new uint[](marketIds.length);
        for (uint i = 0; i < marketIds.length; i++) {
            results[i] = borrowing.collateralRatio(marketIds[i], collateralIndexes[i], borrowers[i]);
        }
        return results;
    }

    function getBorrowingStat(IOPBorrowing borrowing, address borrower, uint16 marketId, bool collateralIndex) external returns (BorrowingStatVars memory) {
        BorrowingStatVars memory result;
        result.collateral = OPBorrowingStorage(address(borrowing)).activeCollaterals(borrower, marketId, collateralIndex);
        if (result.collateral == 0) {
            result.status = BorrowingStatus.NOP;
            return result;
        }
        if (borrowing.collateralRatio(marketId, collateralIndex, borrower) >= 10000) {
            result.status = BorrowingStatus.HEALTHY;
            return result;
        }

        LPoolInterface borrowPool;
        address collateralToken;
        address borrowToken;
        bytes memory dexData;
        {
            (LPoolInterface pool0, LPoolInterface pool1, address token0, address token1, uint32 dex) = OPBorrowingStorage(address(borrowing)).markets(marketId);
            borrowPool = collateralIndex ? pool0 : pool1;
            collateralToken = collateralIndex ? token1 : token0;
            borrowToken = collateralIndex ? token0 : token1;
            dexData = OPBorrowingLib.uint32ToBytes(dex);
            (, , , , result.lastUpdateTime) = OPBorrowingStorage(address(borrowing)).dexAgg().getPriceCAvgPriceHAvgPrice(
                collateralToken,
                borrowToken,
                60,
                dexData
            );
            if (dexData.isUniV2Class()) {
                OPBorrowingStorage(address(borrowing)).openLev().updatePrice(marketId, dexData);
            }
        }
        uint collateral = OPBorrowingLib.shareToAmount(
            result.collateral,
            OPBorrowingStorage(address(borrowing)).totalShares(collateralToken),
            IERC20(collateralToken).balanceOf(address(borrowing))
        );
        uint borrowed = borrowPool.borrowBalanceCurrent(borrower);
        (uint collateralRatio, , , , , , , , , , ) = OPBorrowingStorage(address(borrowing)).marketsConf(marketId);
        uint maxPrice;
        uint denominator;
        {
            DexAggregatorInterface dexAgg = OPBorrowingStorage(address(borrowing)).dexAgg();
            (uint price, uint cAvgPrice, uint hAvgPrice, uint8 decimals, ) = dexAgg.getPriceCAvgPriceHAvgPrice(collateralToken, borrowToken, 60, dexData);
            maxPrice = Utils.maxOf(Utils.maxOf(price, cAvgPrice), hAvgPrice);
            denominator = (10 ** uint(decimals));
        }
        if ((((collateral * maxPrice) / denominator) * collateralRatio) / RATIO_DENOMINATOR < borrowed) {
            result.status = BorrowingStatus.LIQUIDATING;
            return result;
        }
        if (!dexData.isUniV2Class() || block.timestamp < result.lastUpdateTime + 60) {
            result.status = BorrowingStatus.WAITING;
            return result;
        }
        result.status = BorrowingStatus.UPDATING_PRICE;
        return result;
    }

    function getBorrowersCollateral(
        IOPBorrowing borrowing,
        uint16 marketId,
        address[] calldata borrowers,
        bool[] calldata collateralIndexes
    ) external view returns (CollateralVars[] memory results) {
        results = new CollateralVars[](borrowers.length);
        (LPoolInterface pool0, LPoolInterface pool1, , , ) = OPBorrowingStorage(address(borrowing)).markets(marketId);
        for (uint i = 0; i < borrowers.length; i++) {
            CollateralVars memory item;
            item.collateral = OPBorrowingStorage(address(borrowing)).activeCollaterals(borrowers[i], marketId, collateralIndexes[i]);
            if (item.collateral > 0) {
                item.collateralRatio = borrowing.collateralRatio(marketId, collateralIndexes[i], borrowers[i]);
                LPoolInterface borrowPool = collateralIndexes[i] ? pool0 : pool1;
                item.borrowing = borrowPool.borrowBalanceCurrent(borrowers[i]);
            }
            results[i] = item;
        }
        return results;
    }
}