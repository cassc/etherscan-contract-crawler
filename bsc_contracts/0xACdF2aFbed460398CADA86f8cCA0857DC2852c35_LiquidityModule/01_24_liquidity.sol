// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.4;

import "../interfaces/IBiswapPoolV3.sol";
import "../interfaces/IBiswapCallback.sol";
import "../interfaces/IBiswapFactoryV3.sol";

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

contract LiquidityModule {

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

    /// @notice the fee growth as a 128-bit fixpoint fees of tokenX collected per 1 liquidity of the pool
    uint256 public feeScaleX_128;
    /// @notice the fee growth as a 128-bit fixpoint fees of tokenY collected per 1 liquidity of the pool
    uint256 public feeScaleY_128;

    uint160 sqrtRate_96;

    /// @notice some values of pool
    /// see library State or IBiswapPoolV3#state for more information
    State public state;

    /// @notice the information about a liquidity by the liquidity's key
    mapping(bytes32 =>Liquidity.Data) public liquidities;

    /// @notice 256 packed point (orderOrEndpoint>0) boolean values. See PointBitmap for more information
    mapping(int16 =>uint256) public pointBitmap;

    /// @notice returns information of a point in the pool, see Point library of IBiswapPoolV3#poitns for more information
    mapping(int24 =>Point.Data) public points;
    /// @notice information about a point whether has limit order and whether as an liquidity's endpoint
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


    event ChangeLiquidityState(Point.Data lp, Point.Data rp, int24 lpn, int24 rpn);

    // data used when removing liquidity
    struct WithdrawRet {
        // total amount of tokenX refund after withdraw
        uint256 x;
        // total amount of tokenY refund after withdraw
        uint256 y;
        // amount of refund tokenX at current point after withdraw
        uint256 xc;
        // amount of refund tokenY at current point after withdraw
        uint256 yc;
        // value of liquidityX at current point after withdraw
        uint128 liquidityX;
    }

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

    /// @dev Add / Dec liquidity
    /// @param minter the minter of the liquidity
    /// @param leftPoint left endpoint of the segment
    /// @param rightPoint right endpoint of the segment, [leftPoint, rightPoint)
    /// @param delta delta liquidity, positive for adding
    /// @param currentPoint current price point on the axies
    function _updateLiquidity(
        address minter,
        int24 leftPoint,
        int24 rightPoint,
        int128 delta,
        int24 currentPoint,
        uint16 feeToVote //feeToVote == 0 for remove liquidity
    ) private {
        int24 pd = pointDelta;
        Liquidity.Data storage lq = liquidities.get(minter, leftPoint, rightPoint);
        (uint256 mFeeScaleX_128, uint256 mFeeScaleY_128) = (feeScaleX_128, feeScaleY_128);
        bool leftFlipped;
        bool rightFlipped;
        feeToVote = feeToVote == 0 ? lq.feeVote : feeToVote;
        // update points
        if (delta != 0) {
            // add / dec liquidity
            leftFlipped = points.updateEndpoint(leftPoint, true, currentPoint, delta, maxLiquidPt, mFeeScaleX_128, mFeeScaleY_128, feeToVote);
            rightFlipped = points.updateEndpoint(rightPoint, false, currentPoint, delta, maxLiquidPt, mFeeScaleX_128, mFeeScaleY_128, feeToVote);
        }
        // get sub fee scale of the range
        {
            (uint256 accFeeXIn_128, uint256 accFeeYIn_128) =
            points.getSubFeeScale(
                leftPoint, rightPoint, currentPoint, mFeeScaleX_128, mFeeScaleY_128
            );
            lq.update(delta, accFeeXIn_128, accFeeYIn_128, feeToVote);
        }
        // update bitmap
        if (leftFlipped) {
            int24 leftVal = orderOrEndpoint.getOrderOrEndptVal(leftPoint, pd);
            if (delta > 0) {
                orderOrEndpoint.setOrderOrEndptVal(leftPoint, pd, leftVal | 1);
                if (leftVal == 0) {
                    pointBitmap.setOne(leftPoint, pd);
                }
            } else {
                int24 newVal = leftVal & 2;
                orderOrEndpoint.setOrderOrEndptVal(leftPoint, pd, newVal);
                if (newVal == 0) {
                    pointBitmap.setZero(leftPoint, pd);
                }
                delete points[leftPoint];
            }
        }
        if (rightFlipped) {
            int24 rightVal = orderOrEndpoint.getOrderOrEndptVal(rightPoint, pd);
            if (delta > 0) {
                orderOrEndpoint.setOrderOrEndptVal(rightPoint, pd, rightVal | 1);
                if (rightVal == 0) {
                    pointBitmap.setOne(rightPoint, pd);
                }
            } else {
                int24 newVal = rightVal & 2;
                orderOrEndpoint.setOrderOrEndptVal(rightPoint, pd, newVal);
                if (newVal == 0) {
                    pointBitmap.setZero(rightPoint, pd);
                }
                delete points[rightPoint];
            }
        }
        emit ChangeLiquidityState(points[leftPoint], points[rightPoint], leftPoint, rightPoint);
    }

    function _computeDepositYc(
        uint128 liquidDelta,
        uint160 sqrtPrice_96
    ) private pure returns (uint128 y) {
        // to simplify computation,
        // minter is required to deposit only token y in point of current price
        uint256 amount = MulDivMath.mulDivCeil(
            liquidDelta,
            sqrtPrice_96,
            TwoPower.Pow96
        );
        y = uint128(amount);
        require (y == amount, "YC OFL");
    }

    /// @dev [leftPoint, rightPoint)
    function _computeDepositXY(
        uint128 liquidDelta,
        int24 leftPoint,
        int24 rightPoint,
        State memory currentState
    ) private view returns (uint128 x, uint128 y, uint128 yc) {
        x = 0;
        uint256 amountY = 0;
        int24 pc = currentState.currentPoint;
        uint160 sqrtPrice_96 = currentState.sqrtPrice_96;
        uint160 sqrtPriceR_96 = LogPowMath.getSqrtPrice(rightPoint);
        uint160 _sqrtRate_96 = sqrtRate_96;
        if (leftPoint < pc) {
            uint160 sqrtPriceL_96 = LogPowMath.getSqrtPrice(leftPoint);
            uint256 yl;
            if (rightPoint < pc) {
                yl = AmountMath.getAmountY(liquidDelta, sqrtPriceL_96, sqrtPriceR_96, _sqrtRate_96, true);
            } else {
                yl = AmountMath.getAmountY(liquidDelta, sqrtPriceL_96, sqrtPrice_96, _sqrtRate_96, true);
            }
            amountY += yl;
        }
        if (rightPoint > pc) {
            // we need compute XR
            int24 xrLeft = (leftPoint > pc) ? leftPoint : pc + 1;
            uint256 xr = AmountMath.getAmountX(
                liquidDelta,
                xrLeft,
                rightPoint,
                sqrtPriceR_96,
                _sqrtRate_96,
                true
            );
            x = uint128(xr);
            require(x == xr, "XOFL");
        }
        if (leftPoint <= pc && rightPoint > pc) {
            // we need compute yc at point of current price
            yc = _computeDepositYc(
                liquidDelta,
                sqrtPrice_96
            );
            amountY += yc;
        } else {
            yc = 0;
        }
        y = uint128(amountY);
        require(y == amountY, "YOFL");
    }

    /// @notice Compute some values (refund token amount, currX/currY in state) when removing liquidity
    /// @param liquidDelta amount of liquidity user wants to withdraw
    /// @param leftPoint left endpoint of liquidity
    /// @param rightPoint right endpoint of liquidity
    /// @param currentState current state values of pool
    /// @return withRet a WithdrawRet struct object containing values computed, see WithdrawRet for more information
    function _computeWithdrawXY(
        uint128 liquidDelta,
        int24 leftPoint,
        int24 rightPoint,
        State memory currentState
    ) private view returns (WithdrawRet memory withRet) {
        uint256 amountY = 0;
        uint256 amountX = 0;
        int24 pc = currentState.currentPoint;
        uint160 sqrtPrice_96 = currentState.sqrtPrice_96;
        uint160 sqrtPriceR_96 = LogPowMath.getSqrtPrice(rightPoint);
        uint160 _sqrtRate_96 = sqrtRate_96;
        if (leftPoint < pc) {
            uint160 sqrtPriceL_96 = LogPowMath.getSqrtPrice(leftPoint);
            uint256 yl;
            if (rightPoint < pc) {
                yl = AmountMath.getAmountY(liquidDelta, sqrtPriceL_96, sqrtPriceR_96, _sqrtRate_96, false);
            } else {
                yl = AmountMath.getAmountY(liquidDelta, sqrtPriceL_96, sqrtPrice_96, _sqrtRate_96, false);
            }
            amountY += yl;
        }
        if (rightPoint > pc) {
            // we need compute XR
            int24 xrLeft = (leftPoint > pc) ? leftPoint : pc + 1;
            uint256 xr = AmountMath.getAmountX(
                liquidDelta,
                xrLeft,
                rightPoint,
                sqrtPriceR_96,
                _sqrtRate_96,
                false
            );
            amountX += xr;
        }
        if (leftPoint <= pc && rightPoint > pc) {
            uint128 originLiquidityY = currentState.liquidity - currentState.liquidityX;
            uint128 withdrawedLiquidityY = (originLiquidityY < liquidDelta) ? originLiquidityY : liquidDelta;
            uint128 withdrawedLiquidityX = liquidDelta - withdrawedLiquidityY;
            withRet.yc = MulDivMath.mulDivFloor(withdrawedLiquidityY, sqrtPrice_96, TwoPower.Pow96);
            // withdrawedLiquidityX * 2^96 < 2^128*2^96=2^224<2^256
            withRet.xc = uint256(withdrawedLiquidityX) * TwoPower.Pow96 / sqrtPrice_96;
            withRet.liquidityX = currentState.liquidityX - withdrawedLiquidityX;
            amountY += withRet.yc;
            amountX += withRet.xc;
        } else {
            withRet.yc = 0;
            withRet.xc = 0;
            withRet.liquidityX = currentState.liquidityX;
        }
        withRet.y = uint128(amountY);
        require(withRet.y == amountY, "YOFL");
        withRet.x = uint128(amountX);
        require(withRet.x == amountX, "XOFL");
    }

    ///overload function mint with default fee vote value
    function mint(
        address recipient,
        int24 leftPt,
        int24 rightPt,
        uint128 liquidDelta,
        bytes calldata data
    ) external returns (uint256 amountX, uint256 amountY) {
        uint16 feeToVote = state.fee; //Take current fee value and vote for it
        (amountX, amountY) = mint(recipient, leftPt, rightPt, liquidDelta, feeToVote, data);
    }

    /// Delegate call implementation for IBiswapPoolV3#mint.
    function mint(
        address recipient,
        int24 leftPt,
        int24 rightPt,
        uint128 liquidDelta,
        uint16 feeToVote,
        bytes calldata data
    ) public returns (uint256 amountX, uint256 amountY) {
        require(leftPt < rightPt, "LR");
        require(leftPt >= leftMostPt, "LO");
        require(rightPt <= rightMostPt, "HO");
        require(int256(rightPt) - int256(leftPt) < RIGHT_MOST_PT, "TL");
        int24 pd = pointDelta;
        require(leftPt % pd == 0, "LPD");
        require(rightPt % pd == 0, "RPD");
        int128 ld = int128(liquidDelta);
        require(ld > 0, "LP");
        if (recipient == address(0)) {
            recipient = msg.sender;
        }
        State memory currentState = state;
        require(IBiswapFactoryV3(factory).checkFeeInRange(feeToVote, fee), "FOR");
        // add a liquidity segment to the pool
        _updateLiquidity(
            recipient,
            leftPt,
            rightPt,
            ld,
            currentState.currentPoint,
            feeToVote
        );
        // compute amount of tokenx and tokeny should be paid from minter
        (uint256 x, uint256 y, uint256 yc) = _computeDepositXY(
            liquidDelta,
            leftPt,
            rightPt,
            currentState
        );
        // update state
        if (yc > 0) {
            // if (!currentState.allX) {
            //     state.currY = currentState.currY + yc;
            // } else {
            //     state.allX = false;
            //     state.currX = MulDivMath.mulDivFloor(currentState.liquidity, TwoPower.Pow96, currentState.sqrtPrice_96);
            //     state.currY = yc;
            // }
            state.liquidity = currentState.liquidity + liquidDelta;
            state.feeTimesL += liquidDelta * feeToVote;
            state.fee = uint16(state.feeTimesL / state.liquidity);
        }
        uint256 bx;
        uint256 by;
        if (x > 0) {
            bx = balanceX();
        }
        if (y > 0) {
            by = balanceY();
        }
        if (x > 0 || y > 0) {
            // minter's callback to pay
            IBiswapMintCallback(msg.sender).mintDepositCallback(x, y, data);
        }
        if (x > 0) {
            require(bx + x <= balanceX(), "NEX"); // not enough x from minter
        }
        if (y > 0) {
            require(by + y <= balanceY(), "NEY"); // not enough y from minter
        }
        amountX = x;
        amountY = y;
    }

    /// Delegate call implementation for IBiswapPoolV3#burn.
    function burn(
        int24 leftPt,
        int24 rightPt,
        uint128 liquidDelta
    ) external returns (uint256 amountX, uint256 amountY) {
        // it is not necessary to check leftPt rightPt with [leftMostPt, rightMostPt]
        // because we haved checked it in the mint(...)
        require(leftPt < rightPt, "LR");
        int24 pd = pointDelta;
        require(leftPt % pd == 0, "LPD");
        require(rightPt % pd == 0, "RPD");
        State memory currentState = state;
        uint128 liquidity = currentState.liquidity;
        // add a liquidity segment to the pool
        require(liquidDelta <= uint128(type(int128).max), 'LQ127');
        int256 nlDelta = -int256(uint256(liquidDelta));
        require(int128(nlDelta) == nlDelta, "DO");
        _updateLiquidity(
            msg.sender,
            leftPt,
            rightPt,
            int128(nlDelta),
            currentState.currentPoint,
            0
        );
        // compute amount of tokenx and tokeny should be paid from minter
        WithdrawRet memory withRet = _computeWithdrawXY(
            liquidDelta,
            leftPt,
            rightPt,
            currentState
        );
        // update state
        Liquidity.Data storage lq = liquidities.get(msg.sender, leftPt, rightPt);

        if (withRet.yc > 0 || withRet.xc > 0) {
            state.liquidity = liquidity - liquidDelta;
            state.liquidityX = withRet.liquidityX;
            state.feeTimesL -= liquidDelta * lq.feeVote;
            state.fee = state.liquidity == 0 ? fee : uint16(state.feeTimesL / state.liquidity);
        }
        if (withRet.x > 0 || withRet.y > 0) {
            lq.tokenOwedX += withRet.x;
            lq.tokenOwedY += withRet.y;
        }
        return (withRet.x, withRet.y);
    }

    /// Delegate call implementation for IBiswapPoolV3#collect.
    function collect(
        address recipient,
        int24 leftPt,
        int24 rightPt,
        uint256 amountXLim,
        uint256 amountYLim
    ) external returns (uint256 actualAmountX, uint256 actualAmountY) {
        require(amountXLim > 0 || amountYLim > 0, "X+Y>0");
        Liquidity.Data storage lq = liquidities.get(msg.sender, leftPt, rightPt);
        actualAmountX = amountXLim;
        if (actualAmountX > lq.tokenOwedX) {
            actualAmountX = lq.tokenOwedX;
        }
        actualAmountY = amountYLim;
        if (actualAmountY > lq.tokenOwedY) {
            actualAmountY = lq.tokenOwedY;
        }
        lq.tokenOwedX -= actualAmountX;
        lq.tokenOwedY -= actualAmountY;

        actualAmountX = MaxMinMath.min256(actualAmountX, balanceX());
        actualAmountY = MaxMinMath.min256(actualAmountY, balanceY());
        if (actualAmountX > 0) {
            TokenTransfer.transferToken(tokenX, recipient, actualAmountX);
        }
        if (actualAmountY > 0) {
            TokenTransfer.transferToken(tokenY, recipient, actualAmountY);
        }
    }

    /// Delegate call implementation for IBiswapPoolV3#changeFeeVote.
    function changeFeeVote(int24 leftPt, int24 rightPt, uint16 newFeeVote) external {
        require(IBiswapFactoryV3(factory).checkFeeInRange(newFeeVote, fee), "FOR");
        Liquidity.Data memory lq = liquidities.get(msg.sender, leftPt, rightPt);
        uint128 lDelta = lq.liquidity;
        _updateLiquidity(msg.sender, leftPt, rightPt, -int128(lDelta), state.currentPoint, lq.feeVote);
        _updateLiquidity(msg.sender, leftPt, rightPt, int128(lDelta), state.currentPoint, newFeeVote);
        State storage currentState = state;
        if(leftPt <= currentState.currentPoint && rightPt >= currentState.currentPoint){
            currentState.feeTimesL -= lDelta * lq.feeVote;
            currentState.feeTimesL += lDelta * newFeeVote;
            currentState.fee = currentState.liquidity == 0 ? fee : uint16(state.feeTimesL / state.liquidity);
        }
    }

}