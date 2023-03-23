// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../interfaces/IBiswapPoolV3.sol";
import "../interfaces/IBiswapCallback.sol";

import "../libraries/Liquidity.sol";
import "../libraries/Point.sol";
import "../libraries/PointBitmap.sol";
import "../libraries/LogPowMath.sol";
import "../libraries/MulDivMath.sol";
import "../libraries/TwoPower.sol";
import "../libraries/LimitOrder.sol";
import "../libraries/SwapMathY2X.sol";
import "../libraries/SwapMathX2Y.sol";
import "../libraries/SwapMathY2XDesire.sol";
import "../libraries/SwapMathX2YDesire.sol";
import "../libraries/TokenTransfer.sol";
import "../libraries/UserEarn.sol";
import "../libraries/State.sol";
import "../libraries/Oracle.sol";
import "../libraries/OrderOrEndpoint.sol";
import "../libraries/MaxMinMath.sol";

contract LimitOrderModule {

    using Liquidity for mapping(bytes32 =>Liquidity.Data);
    using Liquidity for Liquidity.Data;
    using Point for mapping(int24 =>Point.Data);
    using Point for Point.Data;
    using PointBitmap for mapping(int16 =>uint256);
    using LimitOrder for LimitOrder.Data;
    using UserEarn for UserEarn.Data;
    using UserEarn for mapping(bytes32 =>UserEarn.Data);
    using SwapMathY2X for SwapMathY2X.RangeRetState;
    using SwapMathX2Y for SwapMathX2Y.RangeRetState;
    using Oracle for Oracle.Observation[65535];
    using OrderOrEndpoint for mapping(int24 =>int24);

    int24 internal constant LEFT_MOST_PT = -800000;
    int24 internal constant RIGHT_MOST_PT = 800000;

    /// @notice left most point regularized by pointDelta
    int24 public leftMostPt;
    /// @notice right most point regularized by pointDelta
    int24 public rightMostPt;
    /// @notice maximum liquidSum for each point, see points() in IBiswapPoolV3 or library Point
    uint128 public maxLiquidPt;

    /// @notice address of BiswapFactoryV3
    address public factory;

    /// @notice address of tokenX
    address public tokenX;
    /// @notice address of tokenY
    address public tokenY;
    /// @notice initialize fee amount of this swap pool, 3000 means 0.3%
    uint16 public fee;

    /// @notice minimum number of distance between initialized or limitorder points
    int24 public pointDelta;

    /// @notice the fee growth as a 128-bit fixpoing fees of tokenX collected per 1 liquidity of the pool
    uint256 public feeScaleX_128;
    /// @notice the fee growth as a 128-bit fixpoing fees of tokenY collected per 1 liquidity of the pool
    uint256 public feeScaleY_128;

    uint160 sqrtRate_96;

    /// @notice some values of pool
    /// see library State or IBiswapPoolV3#state for more infomation
    State public state;

    /// @notice the information about a liquidity by the liquidity's key
    mapping(bytes32 =>Liquidity.Data) public liquidities;

    /// @notice 256 packed point (orderOrEndpoint>0) boolean values. See PointBitmap for more information
    mapping(int16 =>uint256) public pointBitmap;

    /// @notice returns infomation of a point in the pool, see Point library of IBiswapPoolV3#poitns for more information
    mapping(int24 =>Point.Data) public points;
    /// @notice infomation about a point whether has limit order and whether as an liquidity's endpoint
    mapping(int24 =>int24) public orderOrEndpoint;
    /// @notice limitOrder info on a given point
    mapping(int24 =>LimitOrder.Data) public limitOrderData;
    /// @notice information about a user's limit order (sell tokenY and earn tokenX)
    mapping(bytes32 => UserEarn.Data) public userEarnX;
    /// @notice information about a user's limit order (sell tokenX and earn tokenY)
    mapping(bytes32 => UserEarn.Data) public userEarnY;
    /// @notice observation data array
    Oracle.Observation[65535] public observations;

    uint256 public totalFeeXCharged;
    uint256 public totalFeeYCharged;

    address private original;

    address private swapModuleX2Y;
    address private swapModuleY2X;
    address private liquidityModule;
    address private limitOrderModule;
    address private flashModule;

    /// @notice percent to charge from miner's fee
    uint24 public feeChargePercent;

    function balanceX() private view returns (uint256) {
        (bool success, bytes memory data) =
            tokenX.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    function balanceY() private view returns (uint256) {
        (bool success, bytes memory data) =
            tokenY.staticcall(abi.encodeWithSelector(IERC20Minimal.balanceOf.selector, address(this)));
        require(success && data.length >= 32);
        return abi.decode(data, (uint256));
    }

    /// Delegate call implementation for IBiswapPoolV3#assignLimOrderEarnY.
    function assignLimOrderEarnY(
        int24 point,
        uint128 assignY,
        bool fromLegacy
    ) external returns (uint128 actualAssignY) {
        actualAssignY = assignY;
        UserEarn.Data storage ue = userEarnY.get(msg.sender, point);
        if (fromLegacy) {
            if (actualAssignY > ue.legacyEarn) {
                actualAssignY = ue.legacyEarn;
            }
            ue.legacyEarn -= actualAssignY;
        } else {
            if (actualAssignY > ue.earn) {
                actualAssignY = ue.earn;
            }
            ue.earn -= actualAssignY;
        }
        ue.earnAssign += actualAssignY;
    }

    /// Delegate call implementation for IBiswapPoolV3#assignLimOrderEarnX.
    function assignLimOrderEarnX(
        int24 point,
        uint128 assignX,
        bool fromLegacy
    ) external returns (uint128 actualAssignX) {
        actualAssignX = assignX;
        UserEarn.Data storage ue = userEarnX.get(msg.sender, point);
        if (fromLegacy) {
            if (actualAssignX > ue.legacyEarn) {
                actualAssignX = ue.legacyEarn;
            }
            ue.legacyEarn -= actualAssignX;
        } else {
            if (actualAssignX > ue.earn) {
                actualAssignX = ue.earn;
            }
            ue.earn -= actualAssignX;
        }
        ue.earnAssign += actualAssignX;
    }

    /// Delegate call implementation for IBiswapPoolV3#decLimOrderWithX.
    function decLimOrderWithX(
        int24 point,
        uint128 deltaX
    ) external returns (uint128 actualDeltaX, uint256 legacyAccEarn, uint128 claimSold, uint128 claimEarn) {
        require(point % pointDelta == 0, "PD");

        UserEarn.Data storage ue = userEarnY.get(msg.sender, point);
        LimitOrder.Data storage pointOrder = limitOrderData[point];
        uint160 sqrtPrice_96 = LogPowMath.getSqrtPrice(point);
        legacyAccEarn = pointOrder.legacyAccEarnY;
        if (legacyAccEarn > ue.lastAccEarn) {
            (pointOrder.legacyEarnY, claimSold, claimEarn) = ue.updateLegacyOrder(0, pointOrder.accEarnY, sqrtPrice_96, pointOrder.legacyEarnY, true);
        } else {
            (actualDeltaX, pointOrder.earnY, claimSold, claimEarn) = ue.decUnlegacyOrder(deltaX, pointOrder.accEarnY, sqrtPrice_96, pointOrder.earnY, true);
            pointOrder.sellingX -= actualDeltaX;

            if (actualDeltaX > 0 && pointOrder.sellingX == 0) {
                int24 newVal = orderOrEndpoint.getOrderOrEndptVal(point, pointDelta) & 1;
                orderOrEndpoint.setOrderOrEndptVal(point, pointDelta, newVal);
                if (newVal == 0) {
                    pointBitmap.setZero(point, pointDelta);
                }
            }
        }

    }

    /// Delegate call implementation for IBiswapPoolV3#decLimOrderWithY.
    function decLimOrderWithY(
        int24 point,
        uint128 deltaY
    ) external returns (uint128 actualDeltaY, uint256 legacyAccEarn, uint128 claimSold, uint128 claimEarn) {
        require(point % pointDelta == 0, "PD");

        UserEarn.Data storage ue = userEarnX.get(msg.sender, point);
        LimitOrder.Data storage pointOrder = limitOrderData[point];
        uint160 sqrtPrice_96 = LogPowMath.getSqrtPrice(point);
        legacyAccEarn = pointOrder.legacyAccEarnX;
        if (legacyAccEarn > ue.lastAccEarn) {
            (pointOrder.legacyEarnX, claimSold, claimEarn) = ue.updateLegacyOrder(0, pointOrder.accEarnX, sqrtPrice_96, pointOrder.legacyEarnX, false);
        } else {
            (actualDeltaY, pointOrder.earnX, claimSold, claimEarn) = ue.decUnlegacyOrder(deltaY, pointOrder.accEarnX, sqrtPrice_96, pointOrder.earnX, false);

            pointOrder.sellingY -= actualDeltaY;

            if (actualDeltaY > 0 && pointOrder.sellingY == 0) {
                int24 newVal = orderOrEndpoint.getOrderOrEndptVal(point, pointDelta) & 1;
                orderOrEndpoint.setOrderOrEndptVal(point, pointDelta, newVal);
                if (newVal == 0) {
                    pointBitmap.setZero(point, pointDelta);
                }
            }
        }

    }

    struct AddLimOrderCacheData {
        uint128 currX;
        uint128 currY;
        uint128 costOffset;
    }

    /// Delegate call implementation for IBiswapPoolV3#allLimOrderWithX.
    function addLimOrderWithX(
        address recipient,
        int24 point,
        uint128 amountX,
        bytes calldata data
    ) external returns (uint128 orderX, uint128 acquireY, uint128 claimSold, uint128 claimEarn) {
        require(point % pointDelta == 0, "PD");
        require(point >= state.currentPoint, "PG");
        require(point <= rightMostPt, "HO");
        require(amountX > 0, "XP");

        // update point order
        LimitOrder.Data storage pointOrder = limitOrderData[point];

        orderX = amountX;
        acquireY = 0;
        uint160 sqrtPrice_96 = LogPowMath.getSqrtPrice(point);

        AddLimOrderCacheData memory addLimOrderCacheData = AddLimOrderCacheData({
            currY: pointOrder.sellingY,
            currX: pointOrder.sellingX,
            costOffset: 0
        });

        if (addLimOrderCacheData.currY > 0) {
            (addLimOrderCacheData.costOffset, acquireY) = SwapMathX2Y.x2YAtPrice(amountX, sqrtPrice_96, addLimOrderCacheData.currY);
            orderX -= addLimOrderCacheData.costOffset;
            addLimOrderCacheData.currY -= acquireY;
            pointOrder.accEarnX = pointOrder.accEarnX + addLimOrderCacheData.costOffset;
            pointOrder.earnX = pointOrder.earnX + addLimOrderCacheData.costOffset;
            pointOrder.sellingY = addLimOrderCacheData.currY;
            if (addLimOrderCacheData.currY > 0) {
                orderX = 0;
            }
        }

        if (orderX > 0) {
            addLimOrderCacheData.currX += orderX;
            pointOrder.sellingX = addLimOrderCacheData.currX;
        }

        UserEarn.Data storage ue = userEarnY.get(recipient, point);
        if (ue.lastAccEarn < pointOrder.legacyAccEarnY) {
            (pointOrder.legacyEarnY, claimSold, claimEarn) = ue.updateLegacyOrder(orderX, pointOrder.accEarnY, sqrtPrice_96, pointOrder.legacyEarnY, true);
        } else {
            (pointOrder.earnY, claimSold, claimEarn) = ue.addUnlegacyOrder(orderX, pointOrder.accEarnY, sqrtPrice_96, pointOrder.earnY, true);
        }
        ue.earnAssign = ue.earnAssign + acquireY;

        // update statusval and bitmap
        if (addLimOrderCacheData.currX == 0 && addLimOrderCacheData.currY == 0) {
            int24 val = orderOrEndpoint.getOrderOrEndptVal(point, pointDelta);
            // val & 2 != 0, because currX == 0, but amountX > 0
            int24 newVal = val & 1;
            orderOrEndpoint.setOrderOrEndptVal(point, pointDelta, newVal);
            if (newVal == 0) {
                pointBitmap.setZero(point, pointDelta);
            }
        } else {
            int24 val = orderOrEndpoint.getOrderOrEndptVal(point, pointDelta);
            if (val & 2 == 0) {
                int24 newVal = val | 2;
                orderOrEndpoint.setOrderOrEndptVal(point, pointDelta, newVal);
                if (val == 0) {
                    pointBitmap.setOne(point, pointDelta);
                }
            }
        }
        require(orderX + addLimOrderCacheData.costOffset > 0, 'p>0');

        // trader pay x
        uint256 bx = balanceX();
        IBiswapAddLimOrderCallback(msg.sender).payCallback(orderX + addLimOrderCacheData.costOffset, 0, data);
        require(balanceX() >= bx + orderX + addLimOrderCacheData.costOffset, "XE");
    }

    /// Delegate call implementation for IBiswapPoolV3#addLimOrderWithY.
    function addLimOrderWithY(
        address recipient,
        int24 point,
        uint128 amountY,
        bytes calldata data
    ) external returns (uint128 orderY, uint128 acquireX, uint128 claimSold, uint128 claimEarn) {
        require(point % pointDelta == 0, "PD");
        require(point <= state.currentPoint, "PL");
        require(point >= leftMostPt, "LO");
        require(amountY > 0, "YP");

        // update point order
        LimitOrder.Data storage pointOrder = limitOrderData[point];

        orderY = amountY;
        acquireX = 0;
        uint160 sqrtPrice_96 = LogPowMath.getSqrtPrice(point);

        AddLimOrderCacheData memory addLimOrderCacheData = AddLimOrderCacheData({
            currY: pointOrder.sellingY,
            currX: pointOrder.sellingX,
            costOffset: 0
        });

        if (addLimOrderCacheData.currX > 0) {
            (addLimOrderCacheData.costOffset, acquireX) = SwapMathY2X.y2XAtPrice(amountY, sqrtPrice_96, addLimOrderCacheData.currX);
            orderY -= addLimOrderCacheData.costOffset;
            addLimOrderCacheData.currX -= acquireX;
            pointOrder.accEarnY = pointOrder.accEarnY + addLimOrderCacheData.costOffset;
            pointOrder.earnY = pointOrder.earnY + addLimOrderCacheData.costOffset;
            pointOrder.sellingX = addLimOrderCacheData.currX;
            if (addLimOrderCacheData.currX > 0) {
                orderY = 0;
            }
        }

        if (orderY > 0) {
            addLimOrderCacheData.currY += orderY;
            pointOrder.sellingY = addLimOrderCacheData.currY;
        }

        UserEarn.Data storage ue = userEarnX.get(recipient, point);
        if (pointOrder.legacyAccEarnX > ue.lastAccEarn) {
            (pointOrder.legacyEarnX, claimSold, claimEarn) = ue.updateLegacyOrder(orderY, pointOrder.accEarnX, sqrtPrice_96, pointOrder.legacyEarnX, false);
        } else {
            (pointOrder.earnX, claimSold, claimEarn) = ue.addUnlegacyOrder(orderY, pointOrder.accEarnX, sqrtPrice_96, pointOrder.earnX, false);
        }
        ue.earnAssign = ue.earnAssign + acquireX;

        // update statusval and bitmap
        if (addLimOrderCacheData.currX == 0 && addLimOrderCacheData.currY == 0) {
            int24 val = orderOrEndpoint.getOrderOrEndptVal(point, pointDelta);
            // val & 2 != 0, because currY == 0, but amountY > 0
            int24 newVal = val & 1;
            orderOrEndpoint.setOrderOrEndptVal(point, pointDelta, newVal);
            if (newVal == 0) {
                pointBitmap.setZero(point, pointDelta);
            }
        } else {
            int24 val = orderOrEndpoint.getOrderOrEndptVal(point, pointDelta);
            if (val & 2 == 0) {
                int24 newVal = val | 2;
                orderOrEndpoint.setOrderOrEndptVal(point, pointDelta, newVal);
                if (val == 0) {
                    pointBitmap.setOne(point, pointDelta);
                }
            }
        }

        require(orderY + addLimOrderCacheData.costOffset > 0, 'p>0');

        // trader pay y
        uint256 by = balanceY();
        IBiswapAddLimOrderCallback(msg.sender).payCallback(0, orderY + addLimOrderCacheData.costOffset, data);
        require(balanceY() >= by + orderY + addLimOrderCacheData.costOffset, "YE");
    }

    /// Delegate call implementation for IBiswapPoolV3#collectLimOrder.
    function collectLimOrder(
        address recipient, int24 point, uint128 collectDec, uint128 collectEarn, bool isEarnY
    ) external returns(uint128 actualCollectDec, uint128 actualCollectEarn) {
        UserEarn.Data storage ue = isEarnY? userEarnY.get(msg.sender, point) : userEarnX.get(msg.sender, point);
        actualCollectDec = collectDec;
        if (actualCollectDec > ue.sellingDec) {
            actualCollectDec = ue.sellingDec;
        }
        ue.sellingDec = ue.sellingDec - actualCollectDec;
        actualCollectEarn = collectEarn;
        if (actualCollectEarn > ue.earnAssign) {
            actualCollectEarn = ue.earnAssign;
        }
        ue.earnAssign = ue.earnAssign - actualCollectEarn;
        (uint256 x, uint256 y) = isEarnY? (actualCollectDec, actualCollectEarn): (actualCollectEarn, actualCollectDec);
        x = MaxMinMath.min256(x, balanceX());
        y = MaxMinMath.min256(y, balanceY());
        if (x > 0) {
            TokenTransfer.transferToken(tokenX, recipient, x);
        }
        if (y > 0) {
            TokenTransfer.transferToken(tokenY, recipient, y);
        }
    }

}