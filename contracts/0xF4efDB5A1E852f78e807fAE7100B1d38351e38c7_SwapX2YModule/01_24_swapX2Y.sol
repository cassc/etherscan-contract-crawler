// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "./interfaces/IiZiSwapPool.sol";
import "./interfaces/IiZiSwapCallback.sol";

import "./libraries/Liquidity.sol";
import "./libraries/Point.sol";
import "./libraries/PointBitmap.sol";
import "./libraries/LogPowMath.sol";
import "./libraries/MulDivMath.sol";
import "./libraries/TwoPower.sol";
import "./libraries/LimitOrder.sol";
import "./libraries/SwapMathY2X.sol";
import "./libraries/SwapMathX2Y.sol";
import "./libraries/SwapMathY2XDesire.sol";
import "./libraries/SwapMathX2YDesire.sol";
import "./libraries/TokenTransfer.sol";
import "./libraries/UserEarn.sol";
import "./libraries/State.sol";
import "./libraries/Oracle.sol";
import "./libraries/OrderOrEndpoint.sol";
import "./libraries/MaxMinMath.sol";
import "./libraries/SwapCache.sol";

contract SwapX2YModule {

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
    /// @notice maximum liquidSum for each point, see points() in IiZiSwapPool or library Point
    uint128 public maxLiquidPt;

    /// @notice address of iZiSwapFactory
    address public factory;

    /// @notice address of tokenX
    address public tokenX;
    /// @notice address of tokenY
    address public tokenY;
    /// @notice fee amount of this swap pool, 3000 means 0.3%
    uint24 public fee;

    /// @notice minimum number of distance between initialized or limitorder points 
    int24 public pointDelta;

    /// @notice the fee growth as a 128-bit fixpoing fees of tokenX collected per 1 liquidity of the pool
    uint256 public feeScaleX_128;
    /// @notice the fee growth as a 128-bit fixpoing fees of tokenY collected per 1 liquidity of the pool
    uint256 public feeScaleY_128;

    uint160 sqrtRate_96;

    /// @notice some values of pool
    /// see library State or IiZiSwapPool#state for more infomation
    State public state;

    /// @notice the information about a liquidity by the liquidity's key
    mapping(bytes32 =>Liquidity.Data) public liquidities;

    /// @notice 256 packed point (orderOrEndpoint>0) boolean values. See PointBitmap for more information
    mapping(int16 =>uint256) public pointBitmap;

    /// @notice returns infomation of a point in the pool, see Point library of IiZiSwapPool#poitns for more information
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

    /// Delegate call implementation for IiZiSwapPool#swapX2Y.
    function swapX2Y(
        address recipient,
        uint128 amount,
        int24 lowPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY) {
        require(amount > 0, "AP");

        lowPt = MaxMinMath.max(lowPt, leftMostPt);
        amountX = 0;
        amountY = 0;
        State memory st = state;
        SwapCache memory cache;
        cache.currFeeScaleX_128 = feeScaleX_128;
        cache.currFeeScaleY_128 = feeScaleY_128;
        cache.finished = false;
        cache._sqrtRate_96 = sqrtRate_96;
        cache.pointDelta = pointDelta;
        cache.currentOrderOrEndpt = orderOrEndpoint.getOrderOrEndptVal(st.currentPoint, cache.pointDelta);
        cache.startPoint = st.currentPoint;
        cache.startLiquidity = st.liquidity;
        cache.timestamp = uint32(block.timestamp);

        while (lowPt <= st.currentPoint && !cache.finished) {

            // step1: fill limit order 
            if (cache.currentOrderOrEndpt & 2 > 0) {
                // amount <= uint128.max
                uint128 amountNoFee = uint128(uint256(amount) * (1e6 - fee) / 1e6);
                if (amountNoFee > 0) {
                    LimitOrder.Data storage od = limitOrderData[st.currentPoint];
                    uint128 currY = od.sellingY;
                    (uint128 costX, uint128 acquireY) = SwapMathX2Y.x2YAtPrice(
                        amountNoFee, st.sqrtPrice_96, currY
                    );
                    if (acquireY < currY || costX >= amountNoFee) {
                        cache.finished = true;
                    }
                    uint128 feeAmount;
                    if (costX >= amountNoFee) {
                        feeAmount = amount - costX;
                    } else {
                        // costX <= amountX <= uint128.max
                        feeAmount = uint128(uint256(costX) * fee / (1e6 - fee));
                        uint256 mod = uint256(costX) * fee % (1e6 - fee);
                        if (mod > 0) {
                            feeAmount += 1;
                        }
                    }
                    totalFeeXCharged += feeAmount;
                    amount -= (costX + feeAmount);
                    amountX = amountX + costX + feeAmount;
                    amountY += acquireY;
                    currY -= acquireY;
                    od.sellingY = currY;
                    od.earnX += costX;
                    od.accEarnX += costX;
                    if (currY == 0) {
                        od.legacyEarnX += od.earnX;
                        od.legacyAccEarnX = od.accEarnX;
                        od.earnX = 0;
                        if (od.sellingX == 0) {
                            int24 newVal = cache.currentOrderOrEndpt & 1;
                            orderOrEndpoint.setOrderOrEndptVal(st.currentPoint, cache.pointDelta, newVal);
                            if (newVal == 0) {
                                pointBitmap.setZero(st.currentPoint, cache.pointDelta);
                            }
                        }
                    }
                } else {
                    cache.finished = true;
                }
            }
            if (cache.finished) {
                break;
            }
            int24 searchStart = st.currentPoint - 1;

            // step2: clear the liquidity if the currentPoint is an endpoint
            if (cache.currentOrderOrEndpt & 1 > 0) {
                // amount <= uint128.max
                uint128 amountNoFee = uint128(uint256(amount) * (1e6 - fee) / 1e6);
                if (amountNoFee > 0) {
                    if (st.liquidity > 0) {
                        SwapMathX2Y.RangeRetState memory retState = SwapMathX2Y.x2YRange(
                            st,
                            st.currentPoint,
                            cache._sqrtRate_96,
                            amountNoFee
                        );
                        cache.finished = retState.finished;
                        uint128 feeAmount;
                        if (retState.costX >= amountNoFee) {
                            feeAmount = amount - retState.costX;
                        } else {
                            // retState.costX <= amount <= uint128.max
                            feeAmount = uint128(uint256(retState.costX) * fee / (1e6 - fee));
                            uint256 mod = uint256(retState.costX) * fee % (1e6 - fee);
                            if (mod > 0) {
                                feeAmount += 1;
                            }
                        }
                        uint256 chargedFeeAmount = uint256(feeAmount) * feeChargePercent / 100;
                        totalFeeXCharged += chargedFeeAmount;

                        cache.currFeeScaleX_128 = cache.currFeeScaleX_128 + MulDivMath.mulDivFloor(feeAmount - chargedFeeAmount, TwoPower.Pow128, st.liquidity);
                        amountX = amountX + retState.costX + feeAmount;
                        amountY += retState.acquireY;
                        amount -= (retState.costX + feeAmount);
                        st.currentPoint = retState.finalPt;
                        st.sqrtPrice_96 = retState.sqrtFinalPrice_96;
                        st.liquidityX = retState.liquidityX;
                    }
                    if (!cache.finished) {
                        Point.Data storage pointdata = points[st.currentPoint];
                        pointdata.passEndpoint(cache.currFeeScaleX_128, cache.currFeeScaleY_128);
                        st.liquidity = Liquidity.liquidityAddDelta(st.liquidity, - pointdata.liquidDelta);
                        st.currentPoint = st.currentPoint - 1;
                        st.sqrtPrice_96 = LogPowMath.getSqrtPrice(st.currentPoint);
                        st.liquidityX = 0;
                    }
                } else {
                    cache.finished = true;
                }
            }
            if (cache.finished || st.currentPoint < lowPt) {
                break;
            }
            int24 nextPt= pointBitmap.nearestLeftOneOrBoundary(searchStart, cache.pointDelta);
            if (nextPt < lowPt) {
                nextPt = lowPt;
            }
            int24 nextVal = orderOrEndpoint.getOrderOrEndptVal(nextPt, cache.pointDelta);
            
            // in [nextPt, st.currentPoint)
            if (st.liquidity == 0) {
                // no liquidity in the range [nextPt, st.currentPoint]
                st.currentPoint = nextPt;
                st.sqrtPrice_96 = LogPowMath.getSqrtPrice(st.currentPoint);
                // st.liquidityX must be 0
                cache.currentOrderOrEndpt = nextVal;
            } else {
                // amount > 0
                // amountNoFee <= amount <= uint128.max
                uint128 amountNoFee = uint128(uint256(amount) * (1e6 - fee) / 1e6);
                if (amountNoFee > 0) {
                    SwapMathX2Y.RangeRetState memory retState = SwapMathX2Y.x2YRange(
                        st, nextPt, cache._sqrtRate_96, amountNoFee
                    );
                    cache.finished = retState.finished;
                    uint128 feeAmount;
                    if (retState.costX >= amountNoFee) {
                        feeAmount = amount - retState.costX;
                    } else {
                        // feeAmount <= retState.costX <= amount <= uint128.max
                        feeAmount = uint128(uint256(retState.costX) * fee / (1e6 - fee));
                        uint256 mod = uint256(retState.costX) * fee % (1e6 - fee);
                        if (mod > 0) {
                            feeAmount += 1;
                        }
                    }
                    amountY += retState.acquireY;
                    amountX = amountX + retState.costX + feeAmount;
                    amount -= (retState.costX + feeAmount);

                    uint256 chargedFeeAmount = uint256(feeAmount) * feeChargePercent / 100;
                    totalFeeXCharged += chargedFeeAmount;
                    
                    cache.currFeeScaleX_128 = cache.currFeeScaleX_128 + MulDivMath.mulDivFloor(feeAmount - chargedFeeAmount, TwoPower.Pow128, st.liquidity);
                    st.currentPoint = retState.finalPt;
                    st.sqrtPrice_96 = retState.sqrtFinalPrice_96;
                    st.liquidityX = retState.liquidityX;
                } else {
                    cache.finished = true;
                }
                if (st.currentPoint == nextPt) {
                    cache.currentOrderOrEndpt = nextVal;
                } else {
                    // not necessary, because finished must be true
                    cache.currentOrderOrEndpt = 0;
                }
            }
            if (st.currentPoint <= lowPt) {
                break;
            }
        }

        if (cache.startPoint != st.currentPoint) {
            (st.observationCurrentIndex, st.observationQueueLen) = observations.append(
                st.observationCurrentIndex,
                cache.timestamp,
                cache.startPoint,
                st.observationQueueLen,
                st.observationNextQueueLen
            );
        }

        // write back fee scale, no fee of y
        feeScaleX_128 = cache.currFeeScaleX_128;
        // write back state
        state = st;
        require(amountY > 0, "PR");
        // transfer y to trader
        TokenTransfer.transferToken(tokenY, recipient, amountY);
        // trader pay x
        require(amountX > 0, "PP");
        uint256 bx = balanceX();
        IiZiSwapCallback(msg.sender).swapX2YCallback(amountX, amountY, data);
        require(balanceX() >= bx + amountX, "XE");
        
    }
    
    /// Delegate call implementation for IiZiSwapPool#swapX2YDesireY.
    function swapX2YDesireY(
        address recipient,
        uint128 desireY,
        int24 lowPt,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY) {
        require(desireY > 0, "AP");

        lowPt = MaxMinMath.max(lowPt, leftMostPt);
        amountX = 0;
        amountY = 0;
        State memory st = state;
        SwapCache memory cache;
        cache.currFeeScaleX_128 = feeScaleX_128;
        cache.currFeeScaleY_128 = feeScaleY_128;
        cache.finished = false;
        cache._sqrtRate_96 = sqrtRate_96;
        cache.pointDelta = pointDelta;
        cache.currentOrderOrEndpt = orderOrEndpoint.getOrderOrEndptVal(st.currentPoint, cache.pointDelta);
        cache.startPoint = st.currentPoint;
        cache.startLiquidity = st.liquidity;
        cache.timestamp = uint32(block.timestamp);
        while (lowPt <= st.currentPoint && !cache.finished) {
            // clear limit order first
            if (cache.currentOrderOrEndpt & 2 > 0) {
                LimitOrder.Data storage od = limitOrderData[st.currentPoint];
                uint128 currY = od.sellingY;
                (uint128 costX, uint128 acquireY) = SwapMathX2YDesire.x2YAtPrice(
                    desireY, st.sqrtPrice_96, currY
                );
                if (acquireY >= desireY) {
                    cache.finished = true;
                }

                uint256 feeAmount = MulDivMath.mulDivCeil(costX, fee, 1e6 - fee);
                totalFeeXCharged += feeAmount;
                desireY = (desireY <= acquireY) ? 0 : desireY - acquireY;
                amountX += (costX + feeAmount);
                amountY += acquireY;
                currY -= acquireY;
                od.sellingY = currY;
                od.earnX += costX;
                od.accEarnX += costX;
                if (currY == 0) {
                    od.legacyEarnX += od.earnX;
                    od.earnX = 0;
                    od.legacyAccEarnX = od.accEarnX;
                    if (od.sellingX == 0) {
                        int24 newVal = cache.currentOrderOrEndpt & 1;
                        orderOrEndpoint.setOrderOrEndptVal(st.currentPoint, cache.pointDelta, newVal);
                        if (newVal == 0) {
                            pointBitmap.setZero(st.currentPoint, cache.pointDelta);
                        }
                    }
                }
            }
            if (cache.finished) {
                break;
            }
            int24 searchStart = st.currentPoint - 1;
            // second, clear the liquid if the currentPoint is an endpoint
            if (cache.currentOrderOrEndpt & 1 > 0) {
                if (st.liquidity > 0) {
                    SwapMathX2YDesire.RangeRetState memory retState = SwapMathX2YDesire.x2YRange(
                        st,
                        st.currentPoint,
                        cache._sqrtRate_96,
                        desireY
                    );
                    cache.finished = retState.finished;
                    
                    uint256 feeAmount = MulDivMath.mulDivCeil(retState.costX, fee, 1e6 - fee);
                    uint256 chargedFeeAmount = feeAmount * feeChargePercent / 100;
                    totalFeeXCharged += chargedFeeAmount;

                    cache.currFeeScaleX_128 = cache.currFeeScaleX_128 + MulDivMath.mulDivFloor(feeAmount - chargedFeeAmount, TwoPower.Pow128, st.liquidity);
                    amountX += (retState.costX + feeAmount);
                    amountY += retState.acquireY;
                    desireY -= MaxMinMath.min(desireY, retState.acquireY);
                    st.currentPoint = retState.finalPt;
                    st.sqrtPrice_96 = retState.sqrtFinalPrice_96;
                    st.liquidityX = retState.liquidityX;
                }
                if (!cache.finished) {
                    Point.Data storage pointdata = points[st.currentPoint];
                    pointdata.passEndpoint(cache.currFeeScaleX_128, cache.currFeeScaleY_128);
                    st.liquidity = Liquidity.liquidityAddDelta(st.liquidity, - pointdata.liquidDelta);
                    st.currentPoint = st.currentPoint - 1;
                    st.sqrtPrice_96 = LogPowMath.getSqrtPrice(st.currentPoint);
                    st.liquidityX = 0;
                }
            }
            if (cache.finished || st.currentPoint < lowPt) {
                break;
            }
            int24 nextPt = pointBitmap.nearestLeftOneOrBoundary(searchStart, cache.pointDelta);
            if (nextPt < lowPt) {
                nextPt = lowPt;
            }
            int24 nextVal = orderOrEndpoint.getOrderOrEndptVal(nextPt, cache.pointDelta);

            // in [nextPt, st.currentPoint)
            if (st.liquidity == 0) {
                // no liquidity in the range [nextPt, st.currentPoint]
                st.currentPoint = nextPt;
                st.sqrtPrice_96 = LogPowMath.getSqrtPrice(st.currentPoint);
                // st.liquidityX must be 0
                cache.currentOrderOrEndpt = nextVal;
            } else {
                // amount > 0
                SwapMathX2YDesire.RangeRetState memory retState = SwapMathX2YDesire.x2YRange(
                    st, nextPt, cache._sqrtRate_96, desireY
                );
                cache.finished = retState.finished;
                    
                uint256 feeAmount = MulDivMath.mulDivCeil(retState.costX, fee, 1e6 - fee);
                uint256 chargedFeeAmount = feeAmount * feeChargePercent / 100;
                totalFeeXCharged += chargedFeeAmount;
                    
                amountY += retState.acquireY;
                amountX += (retState.costX + feeAmount);
                desireY -= MaxMinMath.min(desireY, retState.acquireY);
                    
                cache.currFeeScaleX_128 = cache.currFeeScaleX_128 + MulDivMath.mulDivFloor(feeAmount - chargedFeeAmount, TwoPower.Pow128, st.liquidity);

                st.currentPoint = retState.finalPt;
                st.sqrtPrice_96 = retState.sqrtFinalPrice_96;
                st.liquidityX = retState.liquidityX;

                if (st.currentPoint == nextPt) {
                    cache.currentOrderOrEndpt = nextVal;
                } else {
                    // not necessary, because finished must be true
                    cache.currentOrderOrEndpt = 0;
                }
            }
            if (st.currentPoint <= lowPt) {
                break;
            }
        }
        if (cache.startPoint != st.currentPoint) {
            (st.observationCurrentIndex, st.observationQueueLen) = observations.append(
                st.observationCurrentIndex,
                cache.timestamp,
                cache.startPoint,
                st.observationQueueLen,
                st.observationNextQueueLen
            );
        }

        // write back fee scale, no fee of y
        feeScaleX_128 = cache.currFeeScaleX_128;
        // write back state
        state = st;
        require(amountY > 0, "PR");
        // transfer y to trader
        TokenTransfer.transferToken(tokenY, recipient, amountY);
        // trader pay x
        require(amountX > 0, "PP");
        uint256 bx = balanceX();
        IiZiSwapCallback(msg.sender).swapX2YCallback(amountX, amountY, data);
        require(balanceX() >= bx + amountX, "XE");
    }
    
}